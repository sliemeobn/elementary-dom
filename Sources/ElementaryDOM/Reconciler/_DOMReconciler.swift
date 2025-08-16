public enum _ReconcilerNode<DOMInteractor: _DOMInteracting> {
    case fragment([_ReconcilerNode])
    case dynamic(Dynamic)
    case element(Element)
    case lifecycle(Lifecycle)
    case text(Text)
    case function(Function)
    case nothing

    func collectChildNodes(_ ops: inout ChildLayoutRun) {
        switch self {
        case .fragment(let children):
            for child in children {
                child.collectChildNodes(&ops)
            }
        case .dynamic(let dynamic):
            dynamic.collectChildNodes(&ops)
        case .element(let element):
            element.domNode.applyToOperationsList(&ops)
        case .lifecycle(let lifecycle):
            lifecycle.child.collectChildNodes(&ops)
        case .text(let text):
            text.domNode.applyToOperationsList(&ops)
        case .function(let function):
            function.child.collectChildNodes(&ops)
        case .nothing:
            break
        }
    }

    func startRemoval(_ context: inout Reconciler, completion: @escaping () -> Void) {
        logWarning("startRemoval not implemented")
        completion()
    }
}

public struct _ReconcilerBatch<DOMInteractor: _DOMInteracting>: ~Copyable {
    typealias Node = _ReconcilerNode<DOMInteractor>

    let dom: DOMInteractor
    let reportObservedChange: (Node.Function) -> Void

    private(set) var nodesWithChangedChildren: [Node.Element]
    fileprivate(set) var parentElement: Node.Element
    var pendingFunctions: PendingFunctionQueue
    var depth: Int

    init(
        dom: DOMInteractor,
        parentElement: Node.Element,
        pendingFunctions: consuming PendingFunctionQueue,
        reportObservedChange: @escaping (Node.Function) -> Void
    ) {
        self.dom = dom
        self.parentElement = parentElement
        self.pendingFunctions = pendingFunctions
        self.reportObservedChange = reportObservedChange

        nodesWithChangedChildren = []
        depth = 0
    }

    mutating func registerNodeForChildrenUpdate(_ node: Node.Element) {
        // let domOwner = node.owningDOMReferenceNode()
        // if !nodesWithChangedChildren.contains(where: { $0 === node }) {
        //     nodesWithChangedChildren.append(domOwner)
        // }
    }

    mutating func run() {
        logTrace("performUpdateRun started")

        while let next = pendingFunctions.popNextFunctionNode() {
            next.runUpdate(reconciler: &self)
        }

        for node in nodesWithChangedChildren {
            var ops = Node.ChildLayoutRun()
            node.child.collectChildNodes(&ops)

            //TODO: fance stuff here
            dom.replaceChildren(ops.nodes.map { $0.reference }, in: node.domNode.reference)
        }

        logTrace("performUpdateRun finished")
    }

    struct PendingFunctionQueue: ~Copyable {
        private var functionsToRun: [Node.Function] = []

        var isEmpty: Bool { functionsToRun.isEmpty }

        mutating func popNextFunctionNode() -> Node.Function? {
            functionsToRun.popLast()
        }

        mutating func registerFunctionForUpdate(_ node: Node.Function) {
            // sorted insert by depth in reverse order, avoiding duplicates
            var inserted = false

            for index in functionsToRun.indices {
                let existingNode = functionsToRun[index]
                if existingNode === node {
                    inserted = true
                    break
                }
                if node.depthInTree > existingNode.depthInTree {
                    functionsToRun.insert(node, at: index)
                    inserted = true
                    break
                }
            }
            if !inserted {
                functionsToRun.append(node)
            }
        }
    }
}

extension _ReconcilerNode {
    typealias DOMReference = DOMInteractor.Node
    typealias Reconciler = _ReconcilerBatch<DOMInteractor>

    struct ChildLayoutRun {
        var nodes: [DOMNode]

        init() {
            nodes = []
        }

        mutating func append(_ node: DOMNode) {
            nodes.append(node)
        }
    }

    struct DOMNode {
        enum Status {
            case unchanged
            case added
            case removed
            case moved
        }

        var kind: Status
        let reference: DOMReference

        mutating func applyToOperationsList(_ ops: inout ChildLayoutRun) {
            ops.append(self)
            kind = .unchanged
        }
    }

    public final class Function {
        var value: Value
        var state: _ManagedState?
        let parentElement: Element
        var depthInTree: Int

        var _child: Child
        var child: _ReconcilerNode {
            switch _child {
            case .node(let node):
                return node
            case .factory:
                fatalError("accessed child before it was created")
            }
        }

        init(
            value: Value,
            state: _ManagedState?,
            childNodeFactory: @escaping (_ManagedState?, inout Reconciler) -> _ReconcilerNode,
            reconciler: inout Reconciler
        ) {
            self.value = value
            self.state = state
            self.parentElement = reconciler.parentElement
            self.depthInTree = reconciler.depth + 1
            self._child = .factory(childNodeFactory)

            // we need to break here for scoped reactivity tracking
            reconciler.pendingFunctions.registerFunctionForUpdate(self)
        }

        func patch(_ value: Value, context: inout Reconciler) {
            // TOOD: if value has coparing function we can avoid re-running the function
            self.value = value
            context.pendingFunctions.registerFunctionForUpdate(self)
        }

        func runUpdate(reconciler: inout Reconciler) {
            reconciler.depth = depthInTree
            let reportObservedChange = reconciler.reportObservedChange

            // TODO: expose cancellation mechanism of reactivity and keep track of it
            // canceling on onmount/recalc maybe important for retain cycles

            switch _child {
            case .factory(let factory):
                _child = .node(
                    withReactiveTracking {
                        factory(state, &reconciler)
                    } onChange: { [reportObservedChange, self] in
                        reportObservedChange(self)
                    }
                )
                self._child = .node(child)
            case .node(let node):
                withReactiveTracking {
                    value.patchNode(state, node, &reconciler)
                } onChange: { [reportObservedChange, self] in
                    reportObservedChange(self)
                }
            }
        }

        struct Value {
            // TODO: equality checking
            //var makeNode: (_ManagedState?, inout Reconciler) -> Reconciler.Node
            var patchNode: (_ManagedState?, Reconciler.Node, inout Reconciler) -> Void
        }

        enum Child {
            case factory((_ManagedState?, inout Reconciler) -> _ReconcilerNode)
            case node(_ReconcilerNode)
        }
    }

    public final class Text {
        var value: String
        var domNode: DOMNode

        init(_ newValue: String, context: inout Reconciler) {
            self.value = newValue
            self.domNode = .init(kind: .added, reference: context.dom.createText(newValue))
        }

        func patch(_ newValue: String, context: inout Reconciler) {
            guard !value.utf8Equals(newValue) else { return }
            context.dom.patchText(domNode.reference, with: newValue, replacing: value)
            self.value = newValue
        }
    }

    public final class Lifecycle {
        var value: _LifecycleHook
        let child: _ReconcilerNode

        init(value: _LifecycleHook, child: _ReconcilerNode) {
            self.value = value
            self.child = child
        }

        func patch(_ newChild: _ReconcilerNode, context: inout Reconciler) {
        }
    }

    public final class Element {
        var domNode: DOMNode
        var value: _DomElement
        var _child: _ReconcilerNode?

        var child: _ReconcilerNode { _child! }

        var eventSink: DOMInteractor.EventSink?

        init(value: _DomElement, context: inout Reconciler, childFactory: (inout Reconciler) -> _ReconcilerNode) {
            let domReference = context.dom.createElement(value.tagName)

            self.domNode = .init(kind: .added, reference: domReference)
            self.value = value
            self._child = nil

            //TODO: this is really not ideal, but we need to set the element as current parent
            context.parentElement = self
            self._child = childFactory(&context)
        }

        init(root: DOMReference) {
            self.domNode = .init(kind: .unchanged, reference: root)
            self.value = .init(tagName: "", attributes: .none, listerners: .none)
            self.eventSink = nil
            self._child = nil
        }

        func setChild(_ child: _ReconcilerNode) {
            guard _child == nil else {
                fatalError("child already set")
            }
            self._child = child
        }

        func patch(_ newValue: _DomElement, context: inout Reconciler) {
            context.dom.patchElementAttributes(
                domNode.reference,
                with: newValue.attributes,
                replacing: value.attributes
            )

            context.dom.patchEventListeners(
                domNode.reference,
                with: newValue.listerners,
                replacing: value.listerners,
                sink: getOrMakeEventSync(context.dom)
            )

            self.value = newValue
            context.parentElement = self
        }

        func getOrMakeEventSync(_ dom: DOMInteractor) -> DOMInteractor.EventSink {
            if let sink = eventSink {
                return sink
            } else {
                let sink = dom.makeEventSink { [self] type, event in
                    self.handleEvent(type, event: event)
                }
                eventSink = sink
                return sink
            }
        }

        func handleEvent(_ name: String, event: DOMInteractor.Event) {
            value.listerners.handleEvent(name, event)
        }
    }

    public final class Dynamic {
        var keys: [_ViewKey]
        private var children: [_ReconcilerNode?]
        private var leavingChildren: LeavingChildrenTracker = .init()

        struct LeavingChildrenTracker: ~Copyable {
            struct Entry {
                let key: _ViewKey
                var atIndex: Int
                let value: _ReconcilerNode
            }

            var entries: [Entry] = []

            mutating func append(_ key: _ViewKey, atIndex index: Int, value: _ReconcilerNode) {
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

        init(_ value: some Sequence<(key: _ViewKey, node: _ReconcilerNode)>, context: inout Reconciler) {
            self.keys = []
            self.children = []

            keys.reserveCapacity(value.underestimatedCount)
            children.reserveCapacity(value.underestimatedCount)

            for entry in value {
                keys.append(entry.key)
                children.append(entry.node)
            }
        }

        convenience init(key: _ViewKey, child: _ReconcilerNode, context: inout Reconciler) {
            self.init(CollectionOfOne((key: key, node: child)), context: &context)
        }

        func patch(
            key: _ViewKey,
            context: inout Reconciler,
            makeOrPatchNode: (inout _ReconcilerNode?, inout Reconciler) -> Void
        ) {
            patch(
                CollectionOfOne(key),
                context: &context,
                makeOrPatchNode: { _, node, r in makeOrPatchNode(&node, &r) }
            )
        }

        func patch(
            _ newKeys: some BidirectionalCollection<_ViewKey>,
            context: inout Reconciler,
            makeOrPatchNode: (Int, inout _ReconcilerNode?, inout Reconciler) -> Void
        ) {
            // make key diff on entries
            let diff = newKeys.difference(from: keys).inferringMoves()

            for change in diff {
                switch change {
                case let .remove(offset, element: key, associatedWith: nil):  // exclude associatedWith case as these are moves
                    let node = children.remove(at: offset)
                    guard let node = node else { fatalError("child at index \(offset) is nil") }
                    keys.remove(at: offset)
                    leavingChildren.append(key, atIndex: offset, value: node)
                    node.startRemoval(&context) { [self] in
                        self.completeRemoval(key)
                    }
                case let .insert(offset, element: key, associatedWith: movedFrom):
                    if let movedFrom {
                        let source = RangeSet(Range(movedFrom...movedFrom))

                        children.moveSubranges(source, to: offset)
                        keys.moveSubranges(source, to: offset)

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

        func collectChildNodes(_ ops: inout ChildLayoutRun) {
            // the trick here is to efficiently interleave the leaving nodes with the active nodes to match the DOM order

            var leavingNodes = leavingChildren.entries.makeIterator()
            var nextLeavingNode = leavingNodes.next()

            for index in 0...children.count {
                guard let child = children[index] else {
                    fatalError("unexpected nil child on collection")
                }

                if nextLeavingNode?.atIndex == index {
                    nextLeavingNode!.value.collectChildNodes(&ops)  // cannot be nil if non-nil index is equal
                    nextLeavingNode = leavingNodes.next()
                }

                child.collectChildNodes(&ops)
            }
        }

        // NOTE: maybe use dictionary for index scanning? maybe use collection diffing?
        //let newKeysLookup = Dictionary(uniqueKeysWithValues: newKeys.enumerated().map { ($1, $0) })

        // func patch(
        //     newCount: Int,
        //     context: inout Reconciler,
        //     makeNode: (Int, inout Reconciler) -> _ReconcilerNode,
        //     patchNode: (Int, _ReconcilerNode, inout Reconciler) -> Void
        // ) {
        //     guard keys == nil else {
        //         fatalError("dynamic list has keys")
        //     }

        //     children.reserveCapacity(newCount)

        //     for index in children.indices {
        //         let child = children[index]
        //         patchNode(index, child, &context)
        //     }

        //     if children.count < newCount {
        //         // insert new children
        //         for index in children.count..<newCount {
        //             let child = makeNode(index, &context)
        //             children.append(child)
        //         }
        //     } else {
        //         // remove extra children
        //         for index in children.count..<newCount {
        //             logWarning("removing child at index \(index) because it is no longer needed not implemented")
        //         }
        //     }
        // }
    }
}
