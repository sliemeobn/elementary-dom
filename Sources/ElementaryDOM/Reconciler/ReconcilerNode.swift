public protocol MountedNode: ~Copyable {
    mutating func collectChildren(_ ops: inout ContainerLayoutPass)
    mutating func startRemoval(_ reconciler: inout _ReconcilerBatch)
    mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch)
}

public struct EmptyNode: MountedNode {
    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {}
    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {}
    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {}
}
