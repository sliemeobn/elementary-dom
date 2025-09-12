private extension AnyParentElememnt {
    init(_ element: _ElementNode<some _Reconcilable & ~Copyable>) {
        self.identifier = element.identifier
        self.reportChangedChildren = element.reportChangedChildren
    }
}

public final class _ElementNode<ChildNode>: _Reconcilable where ChildNode: _Reconcilable & ~Copyable {
    // TODO: remove this struct
    struct Value {
        let tagName: String
        var modifiers: [any DOMElementModifier]
    }

    var value: Value
    var child: ChildNode!

    var domNode: ManagedDOMReference?
    var mountedModifieres: [AnyUnmountable]?

    var eventSink: DOM.EventSink?
    var childrenLayoutStatus: ChildrenLayoutStatus = .init()

    let scheduler: Scheduler  // TODO: maybe find a way to not hold on to this

    struct ChildrenLayoutStatus {
        var isDirty: Bool = false
        var count: Int = 0
    }

    private(set) var asParentRef: AnyParentElememnt!

    var identifier: String!

    init(value: Value, context: inout _RenderContext, makeChild: (inout _RenderContext) -> ChildNode) {
        precondition(context.parentElement != nil, "parent element must be set")

        self.value = value
        self.scheduler = context.scheduler
        self.identifier = "\(value.tagName):\(ObjectIdentifier(self))"
        self.asParentRef = AnyParentElememnt(self)

        logTrace("created element \(identifier!) in \(context.parentElement!.identifier)")

        context.commitPlan.addNodeAction(CommitAction(run: createDOMNode(_:)))
        context.parentElement?.reportChangedChildren(.elementAdded, &context)

        context.withCurrentLayoutContainer(asParentRef) {
            self.child = makeChild(&$0)
        }
    }

    init(
        root: DOM.Node,
        context: inout _RenderContext,
        makeChild: (inout _RenderContext) -> ChildNode
    ) {
        self.domNode = .init(reference: root, status: .unchanged)
        self.value = .init(tagName: "<root>", modifiers: .init())
        self.eventSink = nil
        self.scheduler = context.scheduler
        self.identifier = "\("_root_"):\(ObjectIdentifier(self))"
        self.asParentRef = AnyParentElememnt(self)

        context.withCurrentLayoutContainer(asParentRef!) { context in
            self.child = makeChild(&context)
        }
    }

    func withCurrentLayoutContainer(_ context: inout _RenderContext, block: (_ context: inout _RenderContext) -> Void) {
        context.withCurrentLayoutContainer(asParentRef!) { context in
            block(&context)
        }
    }

    func createDOMNode(_ context: inout _CommitContext) {
        logTrace("creating DOM node for element \(value.tagName)")
        precondition(domNode == nil, "element already has a DOM node")
        let ref = context.dom.createElement(value.tagName)
        self.domNode = ManagedDOMReference(reference: ref, status: .added)

        self.mountedModifieres = value.modifiers.map {
            $0.mount(ref, &context)
        }
    }

    func reportChangedChildren(_ change: AnyParentElememnt.Change, context: inout _RenderContext) {
        // TODO: count needed storage for children

        if !childrenLayoutStatus.isDirty {
            childrenLayoutStatus.isDirty = true

            context.commitPlan.addPlacementAction(CommitAction(run: performLayout(_:)))
        }
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        assert(domNode != nil, "unitialized element in layout pass")
        self.domNode?.collectLayoutChanges(&ops)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        switch op {
        case .startRemoval:
            assert(domNode != nil, "unitialized element in startRemoval")
            // TODO: transitions
            domNode?.status = .removed
            reconciler.parentElement!.reportChangedChildren(.elementRemoved, &reconciler)
        case .cancelRemoval:
            fatalError("not implemented")
        case .markAsMoved:
            assert(domNode != nil, "unitialized element in markAsMoved")
            domNode?.status = .moved
            reconciler.parentElement!.reportChangedChildren(.elementChanged, &reconciler)
        }
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        let c = self.child.take()!
        c.unmount(&context)

        mountedModifieres?.forEach { $0.unmount(&context) }
        mountedModifieres = nil

        self.domNode = nil
        self.eventSink = nil
        self.asParentRef = nil
    }

    func performLayout(_ context: inout _CommitContext) {
        guard let ref = domNode?.reference else {
            preconditionFailure("unitialized element in commitChanges - maybe this can be fine?")
        }

        guard childrenLayoutStatus.isDirty else {
            assertionFailure("layout triggered on non-dirty node")
            return
        }
        childrenLayoutStatus.isDirty = false
        var ops = ContainerLayoutPass()  // TODO: initialize with count, could be allocationlessly somehow

        child!.collectChildren(&ops, &context)

        if ops.canBatchReplace {
            if ops.isAllRemovals {
                context.dom.replaceChildren([], in: ref)
            } else if ops.isAllAdditions {
                context.dom.replaceChildren(ops.entries.map { $0.reference }, in: ref)
            } else {
                fatalError("cannot batch replace children of \(ref) because it is not all removals or all additions")
            }
        } else {
            var sibling: DOM.Node?

            for entry in ops.entries.reversed() {
                switch entry.kind {
                case .added, .moved:
                    context.dom.insertChild(entry.reference, before: sibling, in: ref)
                    sibling = entry.reference
                case .removed:
                    context.dom.removeChild(entry.reference, from: ref)
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
    mutating func collectLayoutChanges(_ ops: inout ContainerLayoutPass) {
        ops.append(.init(kind: status, reference: reference))
        self.status = .unchanged
    }
}
