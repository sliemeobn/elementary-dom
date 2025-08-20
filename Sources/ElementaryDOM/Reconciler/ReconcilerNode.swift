public protocol MountedNode: ~Copyable {
    mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _ReconcilerBatch)

    mutating func collectChildren(_ ops: inout ContainerLayoutPass)
}

public struct EmptyNode: MountedNode {
    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _ReconcilerBatch) {}

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {}
}

public enum _ReconcileOp {
    case startRemoval
    case cancelRemoval
    case markAsMoved
}
