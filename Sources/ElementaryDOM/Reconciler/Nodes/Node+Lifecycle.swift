// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public final class Lifecycle<ChildNode: MountedNode>: MountedNode where ChildNode: ~Copyable {
    var value: _LifecycleHook
    var child: ChildNode

    init(value: _LifecycleHook, child: consuming ChildNode) {
        self.value = value
        self.child = consume child
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass) {
        child.collectChildren(&ops)
    }

    public func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        child.startRemoval(&reconciler)
    }

    public func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        child.cancelRemoval(&reconciler)
    }
}
