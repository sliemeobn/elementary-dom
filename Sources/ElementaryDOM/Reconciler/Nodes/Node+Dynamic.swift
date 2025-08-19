// FIXME:NONCOPYABLE this could be a ~Copyable struct once associatedtype is supported
// will be fun to implement with a non-copyable array type of sorts
public final class Dynamic<ChildNode: MountedNode> {
    var keys: [_ViewKey]
    private var children: [ChildNode?]
    private var leavingChildren: LeavingChildrenTracker = .init()

    struct LeavingChildrenTracker: ~Copyable {
        struct Entry {
            let key: _ViewKey
            var atIndex: Int
            var value: ChildNode
        }

        var entries: [Entry] = []

        mutating func append(_ key: _ViewKey, atIndex index: Int, value: consuming ChildNode) {
            // insert in key order
            // Perform a sorted insert by key
            let newEntry = Entry(key: key, atIndex: index, value: value)
            if let insertIndex = entries.firstIndex(where: { $0.atIndex > index }) {
                entries.insert(newEntry, at: insertIndex)
            } else {
                entries.append(newEntry)
            }
        }

        mutating func reflectInsertionAt(_ index: Int) {
            shiftEntriesFromIndexUpwards(index, by: 1)
        }

        mutating func remove(_ key: _ViewKey) {
            guard let index = entries.firstIndex(where: { $0.key == key }) else {
                fatalError("entry with key \(key) not found")
            }

            let entry = entries.remove(at: index)
            shiftEntriesFromIndexUpwards(entry.atIndex, by: -1)
        }

        private mutating func shiftEntriesFromIndexUpwards(_ index: Int, by amount: Int) {
            //TODO: span
            for i in entries.indices {
                if entries[i].atIndex >= index {
                    entries[i].atIndex += amount
                }
            }
        }
    }

    init(keys: [_ViewKey], children: [ChildNode?]) {
        assert(keys.count == children.count)
        self.keys = keys
        self.children = children
    }

    convenience init(_ value: some Sequence<(key: _ViewKey, node: ChildNode)>, context: inout _ReconcilerBatch) {
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

    convenience init(key: _ViewKey, child: ChildNode, context: inout _ReconcilerBatch) {
        self.init(CollectionOfOne((key: key, node: child)), context: &context)
    }

    func patch(
        key: _ViewKey,
        context: inout _ReconcilerBatch,
        makeOrPatchNode: (inout ChildNode?, inout _ReconcilerBatch) -> Void
    ) {
        patch(
            CollectionOfOne(key),
            context: &context,
            makeOrPatchNode: { _, node, r in makeOrPatchNode(&node, &r) }
        )
    }

    func patch(
        _ newKeys: some BidirectionalCollection<_ViewKey>,
        context: inout _ReconcilerBatch,
        makeOrPatchNode: (Int, inout ChildNode?, inout _ReconcilerBatch) -> Void
    ) {
        // make key diff on entries
        let diff = newKeys.difference(from: keys).inferringMoves()

        for change in diff {
            switch change {
            case let .remove(offset, element: key, associatedWith: nil):  // exclude associatedWith case as these are moves
                let node = children.remove(at: offset)
                guard var node = node else { fatalError("child at index \(offset) is nil") }
                keys.remove(at: offset)
                node.startRemoval(reconciler: &context)

                leavingChildren.append(key, atIndex: offset, value: node)
            case let .insert(offset, element: key, associatedWith: movedFrom):
                if let movedFrom {
                    children.moveForward(from: movedFrom, to: offset)
                    keys.moveForward(from: movedFrom, to: offset)

                    // NOTE: not available in embedded
                    // let source = RangeSet(Range(movedFrom...movedFrom))
                    // children.moveSubranges(source, to: offset)
                    // keys.moveSubranges(source, to: offset)

                    // NOTE: maybe adjust indices of leaving children?
                } else {
                    children.insert(nil, at: offset)
                    keys.insert(key, at: offset)
                    leavingChildren.reflectInsertionAt(offset)
                }
            default:
                fatalError("unexpected diff")
            }
        }

        // run update / patch functions on all nodes
        for index in children.indices {
            makeOrPatchNode(index, &children[index], &context)
        }
    }

    func completeRemoval(_ key: _ViewKey) {
        // TOOD: something -> register DOM node update?
        leavingChildren.remove(key)
    }
}

extension Dynamic: MountedNode {
    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        for index in children.indices {
            children[index]?.startRemoval(reconciler: &reconciler)
        }
    }

    public func runLayoutPass(_ ops: inout ContainerLayoutPass) {
        // the trick here is to efficiently interleave the leaving nodes with the active nodes to match the DOM order

        var leavingNodes = leavingChildren.entries.makeIterator()
        var nextLeavingNode = leavingNodes.next()

        for index in 0..<children.count {
            guard var child = children[index] else {
                fatalError("unexpected nil child on collection")
            }

            if nextLeavingNode?.atIndex == index {
                nextLeavingNode!.value.runLayoutPass(&ops)  // cannot be nil if non-nil index is equal
                nextLeavingNode = leavingNodes.next()
            }

            child.runLayoutPass(&ops)
        }

        while var leavingNode = nextLeavingNode {
            leavingNode.value.runLayoutPass(&ops)
            nextLeavingNode = leavingNodes.next()
        }
    }
}

private extension Array {
    mutating func moveForward(from source: Index, to destination: Index) {
        assert(source > destination)
        let element = self.remove(at: source)
        insert(element, at: destination)
    }
}
