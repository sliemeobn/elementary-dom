public struct _StatefulNode<State, Child: _Reconcilable> {
    var state: State
    var child: Child
    var onUnmount: ((inout _CommitContext) -> Void)?

    init(state: State, child: Child) {
        self.state = state
        self.child = child
    }

    init(_ state: State, _ child: Child) where State: Unmountable {
        self.state = state
        self.child = child
        self.onUnmount = state.unmount(_:)
    }
}

extension _StatefulNode: _Reconcilable {
    public mutating func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child.collectChildren(&ops, &context)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        child.unmount(&context)
        if let onUnmount = onUnmount {
            logTrace("unmounting stateful node")
            onUnmount(&context)
            self.onUnmount = nil
        }
    }
}
