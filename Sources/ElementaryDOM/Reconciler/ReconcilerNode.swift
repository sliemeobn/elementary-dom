public protocol _Reconcilable: ~Copyable {
    mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext)
    //mutating func apply(_ op: _CommitOp, _ context: inout _CommitContext)

    mutating func collectChildren(_ ops: inout ContainerLayoutPass)
}

public enum _ReconcileOp {
    case startRemoval
    case cancelRemoval
    case markAsMoved
}

public enum _CommitOp {
    case destroy
}

public struct EmptyNode: _Reconcilable {
    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {}

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {}
}
