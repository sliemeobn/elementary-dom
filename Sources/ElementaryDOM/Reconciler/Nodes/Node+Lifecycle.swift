// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public final class Lifecycle<ChildNode: MountedNode>: MountedNode where ChildNode: ~Copyable {
    var value: _LifecycleHook
    var child: ChildNode

    init(value: _LifecycleHook, child: consuming ChildNode) {
        self.value = value
        self.child = consume child
    }

    public func runLayoutPass(_ ops: inout ContainerLayoutPass) {
        child.runLayoutPass(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        child.startRemoval(reconciler: &reconciler)
    }
}
