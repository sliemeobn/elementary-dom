enum LifecycleHook {
    case onMount(() -> Void)
    case onUnmount(() -> Void)
    case onMountReturningCancelFunction(() -> () -> Void)
    case __none
}

public final class _LifecycleNode {
    private var value: LifecycleHook
    private var child: AnyReconcilable

    private var onUnmount: (() -> Void)?

    init(value: LifecycleHook, child: consuming AnyReconcilable, context: inout _RenderContext) {
        self.value = value
        self.child = child
    }

    convenience init(value: LifecycleHook, child: consuming some _Reconcilable, context: inout _RenderContext) {
        self.init(value: value, child: AnyReconcilable(child), context: &context)

        let scheduler = context.scheduler

        // Schedule lifecycle hook processing
        switch value {
        case .onMount(let onMount):
            logTrace("scheduling onMount for next tick")
            scheduler.onNextTick(onMount)
        case .onUnmount(let callback):
            // Capture scheduler so unmount doesn't need it
            self.onUnmount = { scheduler.onNextTick(callback) }
        case .onMountReturningCancelFunction(let onMountReturningCancelFunction):
            scheduler.onNextTick {
                let cancelFunc = onMountReturningCancelFunction()
                // TODO: this looks dangerous, we could race with unmount?
                self.onUnmount = { scheduler.onNextTick(cancelFunc) }
            }
        case .__none:
            break
        }
        self.value = .__none
    }

    func patch<Node: _Reconcilable>(context: inout _RenderContext, patchNode: (Node, inout _RenderContext) -> Void) {
        patchNode(child.unwrap(), &context)
    }
}

extension _LifecycleNode: _Reconcilable {

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }

    public func unmount(_ context: inout _CommitContext) {
        self.value = .__none
        onUnmount?()
        self.onUnmount = nil
        self.child.unmount(&context)
    }
}
