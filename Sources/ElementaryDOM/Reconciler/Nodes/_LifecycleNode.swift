// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public struct _LifecycleNode<ChildNode: _Reconcilable>: _Reconcilable {
    private var value: _LifecycleHook
    var child: ChildNode

    init(value: _LifecycleHook, child: consuming ChildNode) {
        self.value = value
        self.child = consume child
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        child.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }
}
