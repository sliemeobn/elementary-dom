// FIXME:NONCOPYABLE this should be ~Copyable once associatedtype is supported (will be fun to implement a noncopyable version of this ; )
public struct _KeyedNode<ChildNode: _Reconcilable> {
    private var keys: [_ViewKey]
    private var children: [ChildNode?]
    private var leavingChildren: LeavingChildrenTracker = .init()

    init(keys: [_ViewKey], children: [ChildNode?]) {
        assert(keys.count == children.count)
        self.keys = keys
        self.children = children
    }

    init(_ value: some Sequence<(key: _ViewKey, node: ChildNode)>, context: inout _RenderContext) {
        var keys = [_ViewKey]()
        var children = [ChildNode?]()

        keys.reserveCapacity(value.underestimatedCount)
        children.reserveCapacity(value.underestimatedCount)

        for entry in value {
            keys.append(entry.key)
            children.append(entry.node)
        }

        self.init(keys: keys, children: children)
    }

    init(key: _ViewKey, child: ChildNode, context: inout _RenderContext) {
        self.init(CollectionOfOne((key: key, node: child)), context: &context)
    }

    mutating func patch(
        key: _ViewKey,
        context: inout _RenderContext,
        makeOrPatchNode: (inout ChildNode?, inout _RenderContext) -> Void
    ) {
        patch(
            CollectionOfOne(key),
            context: &context,
            makeOrPatchNode: { _, node, r in makeOrPatchNode(&node, &r) }
        )
    }

    mutating func patch(
        _ newKeys: some BidirectionalCollection<_ViewKey>,
        context: inout _RenderContext,
        makeOrPatchNode: (Int, inout ChildNode?, inout _RenderContext) -> Void
    ) {
        // TODO: add fast-pass for empty key list
        let diff = newKeys.difference(from: keys).inferringMoves()
        keys = Array(newKeys)

        if !diff.isEmpty {
            var moversCache: [Int: ChildNode] = [:]

            // is there a way to completely do this in-place?
            // is there a way to do this more sub-rangy?
            // anyway, this way the "move" case is a bit worse, but the rest is in place

            for change in diff {
                switch change {
                case let .remove(offset, element: key, associatedWith: movedTo):
                    guard var node = children.remove(at: offset) else {
                        fatalError("unexpected nil child on collection")
                    }

                    if movedTo != nil {
                        node.apply(.markAsMoved, &context)
                        moversCache[offset] = consume node
                    } else {
                        node.apply(.startRemoval, &context)
                        context.parentElement?.reportChangedChildren(.elementChanged, &context)
                        leavingChildren.append(key, atIndex: offset, value: node)
                    }
                case let .insert(offset, element: key, associatedWith: movedFrom):
                    var node: ChildNode? = nil

                    if let movedFrom {
                        logTrace("move \(key) from \(movedFrom) to \(offset)")
                        node = moversCache.removeValue(forKey: movedFrom)
                        precondition(node != nil, "mover not found in cache")
                    }

                    children.insert(node, at: offset)
                    leavingChildren.reflectInsertionAt(offset)
                }
            }
            precondition(moversCache.isEmpty, "mover cache is not empty")
        }

        // run update / patch functions on all nodes
        for index in children.indices {
            makeOrPatchNode(index, &children[index], &context)
            assert(children[index] != nil, "unexpected nil child on collection")
        }
    }
}

extension _KeyedNode: _Reconcilable {
    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        for index in children.indices {
            children[index]?.apply(op, &reconciler)
        }
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        // the trick here is to efficiently interleave the leaving nodes with the active nodes to match the DOM order
        // the other trick is to stay noncopyable compatible (one fine day we will have lists, associated types and stuff like that)
        // in any case, we need to mutate in place
        var lIndex = 0
        var nextInsertionPoint = leavingChildren.insertionIndex(for: 0)

        for cIndex in children.indices {
            precondition(children[cIndex] != nil, "unexpected nil child on collection")

            if nextInsertionPoint == cIndex {
                let removed = leavingChildren.commitAndCheckRemoval(at: lIndex, ops: &ops, context: &context)
                if !removed { lIndex += 1 }
                nextInsertionPoint = leavingChildren.insertionIndex(for: lIndex)
            }

            children[cIndex]!.collectChildren(&ops, &context)
        }

        while nextInsertionPoint != nil {
            let removed = leavingChildren.commitAndCheckRemoval(at: lIndex, ops: &ops, context: &context)
            if !removed { lIndex += 1 }
            nextInsertionPoint = leavingChildren.insertionIndex(for: lIndex)
        }
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        for index in children.indices {
            children[index]?.unmount(&context)
        }

        children.removeAll()
        for entry in leavingChildren.entries {
            entry.value.unmount(&context)
        }
        leavingChildren.entries.removeAll()
    }
}

private extension _KeyedNode {
    // FIXME:NONCOPYABLE
    struct LeavingChildrenTracker {  //: ~Copyable {
        struct Entry {
            let key: _ViewKey
            var originalMountIndex: Int
            var value: ChildNode
        }

        var entries: [Entry] = []

        func insertionIndex(for index: Int) -> Int? {
            guard index < entries.count else { return nil }

            return entries[index].originalMountIndex
        }

        mutating func append(_ key: _ViewKey, atIndex index: Int, value: consuming ChildNode) {
            // insert in key order
            // Perform a sorted insert by key
            // maybe do it backwards?
            let newEntry = Entry(key: key, originalMountIndex: index, value: value)
            if let insertIndex = entries.firstIndex(where: { $0.originalMountIndex > index }) {
                entries.insert(newEntry, at: insertIndex)
            } else {
                entries.append(newEntry)
            }
        }

        mutating func reflectInsertionAt(_ index: Int) {
            shiftEntriesFromIndexUpwards(index, by: 1)
        }

        mutating func commitAndCheckRemoval(at index: Int, ops: inout ContainerLayoutPass, context: inout _CommitContext) -> Bool {
            let isRemovalCommitted = ops.withRemovalTracking { ops in
                entries[index].value.collectChildren(&ops, &context)
            }

            if isRemovalCommitted {
                let entry = entries.remove(at: index)
                shiftEntriesFromIndexUpwards(entry.originalMountIndex, by: -1)
                entry.value.unmount(&context)
                return true
            } else {
                return false
            }
        }

        private mutating func shiftEntriesFromIndexUpwards(_ index: Int, by amount: Int) {
            //TODO: span
            for i in entries.indices {
                if entries[i].originalMountIndex >= index {
                    entries[i].originalMountIndex += amount
                }
            }
        }
    }
}
