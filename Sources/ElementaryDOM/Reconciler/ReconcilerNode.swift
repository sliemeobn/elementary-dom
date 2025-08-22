public protocol _Reconcilable: ~Copyable {
    mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext)

    mutating func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext)
    consuming func unmount(_ context: inout _CommitContext)
}

public enum _ReconcileOp {
    case startRemoval
    case cancelRemoval
    case markAsMoved
}

public struct _EmptyNode: _Reconcilable {
    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {}

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {}

    public consuming func unmount(_ context: inout _CommitContext) {}
}
