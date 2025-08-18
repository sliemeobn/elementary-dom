public final class Lifecycle<ChildNode: MountedNode>: MountedNode {
    var value: _LifecycleHook
    var child: ChildNode

    init(value: _LifecycleHook, child: ChildNode) {
        self.value = value
        self.child = child
    }

    public func runLayoutPass(_ ops: inout LayoutPass) {
        child.runLayoutPass(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        child.startRemoval(reconciler: &reconciler)
    }
}
