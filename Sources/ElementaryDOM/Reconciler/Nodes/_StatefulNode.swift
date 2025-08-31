public struct _StatefulNode<State, Child: _Reconcilable> {
    var state: State
    var child: Child
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
    }
}
