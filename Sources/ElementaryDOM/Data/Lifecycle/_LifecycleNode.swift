enum LifecycleHook {
    case onMount(() -> Void)
    case onUnmount(() -> Void)
    case onMountReturningCancelFunction(() -> () -> Void)
    case __none
}

// TODO: this can probably be folded into a "stateful node"
// TODO: revise scheduling / timing of these
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

        context.scheduler.addNodeAction(
            CommitAction(run: self.commitLifecycleValue)
        )
    }

    func patch<Node: _Reconcilable>(context: inout _RenderContext, patchNode: (Node, inout _RenderContext) -> Void) {
        patchNode(child.unwrap(), &context)
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

extension _LifecycleNode: _Reconcilable {

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
