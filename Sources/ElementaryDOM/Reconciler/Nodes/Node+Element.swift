private extension AnyLayoutContainer {
    init(_ element: Element<some MountedNode & ~Copyable>) {
        self.identifier = element.identifier
        self.setDirty = element.setDirty
        self.performLayout = element.performChildrenPass
    }
}

public final class Element<ChildNode: MountedNode>: MountedNode where ChildNode: ~Copyable {
    var domNode: ManagedDOMReference
    var value: _DomElement
    private var child: ChildNode!

    var eventSink: DOM.EventSink?
    var childrenLayoutStatus: ChildrenLayoutStatus = .init()
    private(set) var asLayoutContainer: AnyLayoutContainer!

    struct ChildrenLayoutStatus {
        var isDirty: Bool = false
        var count: Int = 0
    }

    var identifier: String {
        "\(value.tagName):\(ObjectIdentifier(self))"
    }

    init(value: _DomElement, context: inout _ReconcilerBatch, makeChild: (inout _ReconcilerBatch) -> ChildNode) {
        let domReference = context.dom.createElement(value.tagName)
        self.domNode = .init(reference: domReference, status: .added)
        self.value = value
        self.asLayoutContainer = AnyLayoutContainer(self)

        context.dom.patchElementAttributes(
            domReference,
            with: value.attributes,
            replacing: .none
        )

        if !value.listerners.listeners.isEmpty {
            self.eventSink = context.dom.makeEventSink(handleEvent(_:event:))

            context.dom.patchEventListeners(
                domReference,
                with: value.listerners,
                replacing: .none,
                sink: eventSink!
            )
        }

        logTrace("created element \(identifier) in \(context.parentElement.identifier)")

        let parent = context.parentElement
        parent.setDirty(true, &context)
        context.parentElement = AnyLayoutContainer(self)
        self.child = makeChild(&context)
        context.parentElement = parent
    }

    init(
        root: DOM.Node,
        makeReconciler: (Element) -> _ReconcilerBatch,
        makeChild: (inout _ReconcilerBatch) -> ChildNode
    ) {
        self.domNode = .init(reference: root, status: .unchanged)
        self.value = .init(tagName: "<root>", attributes: .none, listerners: .none)
        self.eventSink = nil

        logTrace("created root element")

        var reconciler = makeReconciler(self)
        self.child = makeChild(&reconciler)
        reconciler.run()
    }

    func patch(_ newValue: _DomElement, context: inout _ReconcilerBatch, patchChild: (inout ChildNode, inout _ReconcilerBatch) -> Void) {
        logTrace("patching element \(value.tagName)")

        context.dom.patchElementAttributes(
            domNode.reference,
            with: newValue.attributes,
            replacing: value.attributes
        )

        if let eventSink {
            context.dom.patchEventListeners(
                domNode.reference,
                with: newValue.listerners,
                replacing: value.listerners,
                sink: eventSink
            )
        } else {
            assert(newValue.listerners.listeners.isEmpty, "unexpected added listener on element in patch")
        }

        self.value = newValue

        // TODO: use "withParent"
        let oldParent = context.parentElement
        context.parentElement = AnyLayoutContainer(self)
        patchChild(&child, &context)
        context.parentElement = oldParent
    }

    func handleEvent(_ name: String, event: DOM.Event) {
        logTrace("handling event \(name) for element \(value.tagName)")
        value.listerners.handleEvent(name, event)
    }

    func setDirty(isAddition: Bool, reconciler: inout _ReconcilerBatch) {
        // TODO: count needed storage for children

        if !childrenLayoutStatus.isDirty {
            childrenLayoutStatus.isDirty = true
            reconciler.registerNodeForChildrenUpdate(AnyLayoutContainer(self))
        }
    }

    public func runLayoutPass(_ ops: inout LayoutPass) {
        self.domNode.collectLayoutChanges(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        domNode.status = .removed
        reconciler.parentElement.setDirty(false, &reconciler)
    }

    func performChildrenPass(_ reconciler: inout _ReconcilerBatch) {
        guard childrenLayoutStatus.isDirty else {
            assertionFailure("layout triggered on non-dirty node")
            return
        }
        childrenLayoutStatus.isDirty = false
        var ops = LayoutPass()  // TODO: initialize with count, could be allocationlessly

        child.runLayoutPass(&ops)

        if ops.canBatchReplace {
            if ops.isAllRemovals {
                reconciler.dom.replaceChildren([], in: domNode.reference)
            } else if ops.isAllAdditions {
                reconciler.dom.replaceChildren(ops.entries.map { $0.reference }, in: domNode.reference)
            } else {
                fatalError("cannot batch replace children of \(domNode.reference) because it is not all removals or all additions")
            }
        } else {
            var sibling: DOM.Node?

            for entry in ops.entries.reversed() {
                switch entry.kind {
                case .added, .moved:
                    reconciler.dom.insertChild(entry.reference, before: sibling, in: domNode.reference)
                    sibling = entry.reference
                case .removed:
                    reconciler.dom.removeChild(entry.reference, from: domNode.reference)
                case .leaving:
                    sibling = entry.reference
                    // TODO: for FLIP handling
                    break
                case .unchanged:
                    sibling = entry.reference
                    break
                }
            }
        }
    }
}

extension ManagedDOMReference {
    mutating func collectLayoutChanges(_ ops: inout LayoutPass) {
        ops.append(.init(kind: status, reference: reference))
        self.status = .unchanged
    }
}
