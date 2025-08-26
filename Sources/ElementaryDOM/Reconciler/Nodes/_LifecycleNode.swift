// import _Concurrency

public class _LifecycleNode<ChildNode: _Reconcilable> {  // where ChildNode: ~Copyable
    private var value: _LifecycleHook
    var child: ChildNode

    private var onUnmount: (() -> Void)?

    init(value: _LifecycleHook, child: consuming ChildNode, context: inout _RenderContext) {
        self.value = value
        self.child = consume child

        context.commitPlan.addNodeAction(
            CommitAction(run: self.commitLifecycleValue)
        )
    }

    private func commitLifecycleValue(_ context: inout _CommitContext) {
        switch value {
        case .onMount(let onMount):
            logTrace("scheduling onMount prePaint")
            context.addPrePaintAction(onMount)
        case .onUnmount(let onUnmount):
            self.onUnmount = onUnmount
        case .onMountReturningCancelFunction(let onMountReturningCancelFunction):
            context.addPrePaintAction {
                self.onUnmount = onMountReturningCancelFunction()
            }
        case .__none:
            break
        }

        self.value = .__none
    }
}

extension _LifecycleNode: _Reconcilable where ChildNode: _Reconcilable {

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }

    public func unmount(_ context: inout _CommitContext) {
        self.value = .__none
        if let onUnmount = onUnmount {
            context.addPostPaintAction(onUnmount)
            self.onUnmount = nil
        }
        self.child.unmount(&context)
    }
}
