public final class _ConditionalNode {
    enum State {
        case a(AnyReconcilable)
        case b(AnyReconcilable)
        case aWithBLeaving(AnyReconcilable, AnyReconcilable)
        case bWithALeaving(AnyReconcilable, AnyReconcilable)
    }

    private var state: State
    private var context: _ViewContext

    init(a: consuming AnyReconcilable? = nil, b: consuming AnyReconcilable? = nil, context: borrowing _ViewContext) {
        switch (a, b) {
        case (let .some(a), nil):
            self.state = .a(a)
        case (nil, let .some(b)):
            self.state = .b(b)
        default:
            preconditionFailure("either a or b must be provided")
        }

        self.context = copy context
    }

    convenience init(a: consuming some _Reconcilable, context: borrowing _ViewContext) {
        self.init(a: AnyReconcilable(a), context: context)
    }

    convenience init(b: consuming some _Reconcilable, context: borrowing _ViewContext) {
        self.init(b: AnyReconcilable(b), context: context)
    }

    func patchWithA<NodeA: _Reconcilable>(
        reconciler: inout _RenderContext,
        makeNode: (borrowing _ViewContext, inout _RenderContext) -> NodeA,
        updateNode: (NodeA, inout _RenderContext) -> Void
    ) {
        switch state {
        case .a(let a):
            updateNode(a.unwrap(), &reconciler)
            state = .a(a)
        case .b(let b):
            let a = AnyReconcilable(makeNode(context, &reconciler))
            b.apply(.startRemoval, &reconciler)
            self.context.parentElement?.reportChangedChildren(.elementMoved, context: &reconciler)
            state = .aWithBLeaving(a, b)
        case .aWithBLeaving(let a, let b):
            updateNode(a.unwrap(), &reconciler)
            state = .aWithBLeaving(a, b)
        case .bWithALeaving(let b, let a):
            updateNode(a.unwrap(), &reconciler)
            a.apply(.cancelRemoval, &reconciler)
            b.apply(.startRemoval, &reconciler)
            self.context.parentElement?.reportChangedChildren(.elementMoved, context: &reconciler)
            state = .aWithBLeaving(a, b)
        }
    }

    func patchWithB<NodeB: _Reconcilable>(
        reconciler: inout _RenderContext,
        makeNode: (borrowing _ViewContext, inout _RenderContext) -> NodeB,
        updateNode: (NodeB, inout _RenderContext) -> Void
    ) {
        switch state {
        case .b(let b):
            updateNode(b.unwrap(), &reconciler)
            state = .b(b)
        case .a(let a):
            let b = AnyReconcilable(makeNode(context, &reconciler))
            a.apply(.startRemoval, &reconciler)
            self.context.parentElement?.reportChangedChildren(.elementMoved, context: &reconciler)
            state = .bWithALeaving(b, a)
        case .aWithBLeaving(let a, let b):
            updateNode(b.unwrap(), &reconciler)
            state = .bWithALeaving(b, a)
        case .bWithALeaving(let b, let a):
            updateNode(b.unwrap(), &reconciler)
            state = .bWithALeaving(b, a)
        }
    }

}

extension _ConditionalNode: _Reconcilable {
    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        switch state {
        case .a(let a):
            a.collectChildren(&ops, &context)
        case .b(let b):
            b.collectChildren(&ops, &context)
        case .aWithBLeaving(let a, let b):
            a.collectChildren(&ops, &context)

            let isRemovalCompleted = ops.withRemovalTracking { ops in
                b.collectChildren(&ops, &context)
            }

            if isRemovalCompleted {
                b.unmount(&context)
                state = .a(a)
            }
        case .bWithALeaving(let b, let a):
            // NOTE: ordering of a before b is important because we don't want to track moves here
            let isRemovalCompleted = ops.withRemovalTracking { ops in
                a.collectChildren(&ops, &context)
            }

            b.collectChildren(&ops, &context)

            if isRemovalCompleted {
                a.unmount(&context)
                state = .b(b)
            }
        }
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        switch state {
        case .a(let a):
            a.apply(op, &reconciler)
        case .b(let b):
            b.apply(op, &reconciler)
        case .aWithBLeaving(let a, let b), .bWithALeaving(let b, let a):
            a.apply(op, &reconciler)
            b.apply(op, &reconciler)
        }
    }

    public func unmount(_ context: inout _CommitContext) {
        switch state {
        case .a(let a):
            a.unmount(&context)
        case .b(let b):
            b.unmount(&context)
        case .aWithBLeaving(let a, let b), .bWithALeaving(let b, let a):
            a.unmount(&context)
            b.unmount(&context)
        }
    }
}

extension ContainerLayoutPass {
    mutating func withRemovalTracking(_ block: (inout Self) -> Void) -> Bool {
        let index = entries.count
        block(&self)
        var isRemoved = true
        for entry in entries[index..<entries.count] {
            if entry.kind != .removed {
                isRemoved = false
                break
            }
        }
        return isRemoved
    }
}
