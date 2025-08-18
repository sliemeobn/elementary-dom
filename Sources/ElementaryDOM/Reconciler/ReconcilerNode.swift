public protocol MountedNode: ~Copyable {
    mutating func runLayoutPass(_ ops: inout LayoutPass)
    mutating func startRemoval(reconciler: inout _ReconcilerBatch)
}

public struct EmptyNode: MountedNode {
    public mutating func runLayoutPass(_ ops: inout LayoutPass) {}
    public mutating func startRemoval(reconciler: inout _ReconcilerBatch) {}
}
