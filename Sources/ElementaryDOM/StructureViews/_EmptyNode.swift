public final class _EmptyNode: _Reconcilable {
    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {}

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {}

    public func unmount(_ context: inout _CommitContext) {}
}
