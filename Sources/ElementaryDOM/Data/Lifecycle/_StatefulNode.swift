public final class _StatefulNode<State, Child: _Reconcilable> {
    var state: State
    var child: Child
    private var onUnmount: ((inout _CommitContext) -> Void)?

    init(state: State, child: Child) {
        self.state = state
        self.child = child
    }

    init(state: State, child: Child) where State: Unmountable {
        self.state = state
        self.child = child
        self.onUnmount = state.unmount(_:)
    }
}

extension _StatefulNode: _Reconcilable {
    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }

    public func unmount(_ context: inout _CommitContext) {
        child.unmount(&context)
        onUnmount?(&context)
        self.onUnmount = nil
    }
}
