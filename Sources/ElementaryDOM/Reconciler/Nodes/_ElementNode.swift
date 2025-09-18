private extension AnyParentElememnt {
    init(_ element: _ElementNode<some _Reconcilable & ~Copyable>) {
        self.identifier = element.identifier
        self.reportChangedChildren = element.reportChangedChildren
    }
}

public final class _ElementNode<ChildNode>: _Reconcilable where ChildNode: _Reconcilable & ~Copyable {
    var identifier: String = ""
    var child: ChildNode!

    var domNode: ManagedDOMReference?
    var mountedModifieres: [AnyUnmountable]?

    var childrenLayoutStatus: ChildrenLayoutStatus = .init()

    struct ChildrenLayoutStatus {
        var isDirty: Bool = false
        var count: Int = 0
    }

    private(set) var asParentRef: AnyParentElememnt?

    init(
        tag: String,
        viewContext: consuming _ViewContext,
        context: inout _RenderContext,
        makeChild: (borrowing _ViewContext, inout _RenderContext) -> ChildNode
    ) {
        precondition(context.parentElement != nil, "parent element must be set")

        self.identifier = "\(tag):\(ObjectIdentifier(self))"
        self.asParentRef = AnyParentElememnt(self)

        logTrace("created element \(identifier) in \(context.parentElement!.identifier)")

        var viewContext = copy viewContext
        let modifiers = viewContext.takeModifiers()

        context.scheduler.addNodeAction(
            CommitAction { [self] context in
                precondition(self.domNode == nil, "element already has a DOM node")
                let ref = context.dom.createElement(tag)
                self.domNode = ManagedDOMReference(reference: ref, status: .added)

                self.mountedModifieres = modifiers.map {
                    $0.mount(ref, &context)
                }
            }
        )
        context.parentElement?.reportChangedChildren(.elementAdded, &context)

        context.withCurrentLayoutContainer(asParentRef!) { context in
            self.child = makeChild(viewContext, &context)
        }
    }

    init(
        root: DOM.Node,
        context: inout _RenderContext,
        makeChild: (inout _RenderContext) -> ChildNode
    ) {
        self.domNode = .init(reference: root, status: .unchanged)
        self.asParentRef = AnyParentElememnt(self)
        self.identifier = "\("_root_"):\(ObjectIdentifier(self))"

        context.withCurrentLayoutContainer(asParentRef!) { context in
            self.child = makeChild(&context)
        }
    }

    func updateChild(_ context: inout _RenderContext, block: (_ node: inout ChildNode, _ context: inout _RenderContext) -> Void) {
        context.withCurrentLayoutContainer(asParentRef!) { context in
            block(&self.child, &context)
        }
    }

    func reportChangedChildren(_ change: AnyParentElememnt.Change, context: inout _RenderContext) {
        // TODO: count needed storage for children

        if !childrenLayoutStatus.isDirty {
            childrenLayoutStatus.isDirty = true

            context.scheduler.addPlacementAction(CommitAction(run: performLayout(_:)))
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

        for modifier in mountedModifieres! {
            modifier.unmount(&context)
        }
        self.mountedModifieres = nil

        self.domNode = nil
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
