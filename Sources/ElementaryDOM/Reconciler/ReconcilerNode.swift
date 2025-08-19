public protocol MountedNode: ~Copyable {
    mutating func runLayoutPass(_ ops: inout ContainerLayoutPass)
    mutating func startRemoval(reconciler: inout _ReconcilerBatch)
}

public struct EmptyNode: MountedNode {
    public mutating func runLayoutPass(_ ops: inout ContainerLayoutPass) {}
    public mutating func startRemoval(reconciler: inout _ReconcilerBatch) {}
}
