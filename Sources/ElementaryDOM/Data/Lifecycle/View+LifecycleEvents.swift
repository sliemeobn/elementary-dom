import _Concurrency

public extension View {
    func onMount(_ action: @escaping () -> Void) -> some View<Tag> {
        _LifecycleEventView(wrapped: self, listener: .onMount(action))
    }

    func onUnmount(_ action: @escaping () -> Void) -> some View<Tag> {
        _LifecycleEventView(wrapped: self, listener: .onUnmount(action))
    }

    func task(_ task: @escaping () async -> Void) -> some View<Tag> {
        _LifecycleEventView(
            wrapped: self,
            listener: .onMountReturningCancelFunction({ Task { await task() }.cancel })
        )
    }
}

enum LifecycleHook {
    case onMount(() -> Void)
    case onUnmount(() -> Void)
    case onMountReturningCancelFunction(() -> () -> Void)
}

struct _LifecycleEventView<Wrapped: View>: View {
    typealias Tag = Wrapped.Tag
    typealias _MountedNode = _StatefulNode<LifecycleState, Wrapped._MountedNode>

    let wrapped: Wrapped
    let listener: LifecycleHook

    final class LifecycleState: Unmountable {
        var onUnmount: (() -> Void)?
        let scheduler: Scheduler

        init(hook: LifecycleHook, scheduler: Scheduler) {
            self.scheduler = scheduler

            switch hook {
            case .onMount(let onMount):
                scheduler.onNextTick { onMount() }
            case .onUnmount(let callback):
                self.onUnmount = callback
            case .onMountReturningCancelFunction(let onMountReturningCancelFunction):
                scheduler.onNextTick {
                    let cancelFunc = onMountReturningCancelFunction()
                    self.onUnmount = cancelFunc
                }
            }
        }

        func unmount(_ context: inout _CommitContext) {
            scheduler.onNextTick {
                self.onUnmount?()
                self.onUnmount = nil
            }
        }
    }

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        tx: inout _TransactionContext
    ) -> _MountedNode {
        let state = LifecycleState(hook: view.listener, scheduler: tx.scheduler)
        let child = Wrapped._makeNode(view.wrapped, context: context, tx: &tx)

        let node = _StatefulNode(state: state, child: child)
        return node
    }

    static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        tx: inout _TransactionContext
    ) {
        switch view.listener {
        case .onUnmount(let callback):
            // unmount is the only lifecycle hook that can be patched
            node.state.onUnmount = callback
        default:
            break
        }

        Wrapped._patchNode(view.wrapped, node: node.child, tx: &tx)
    }
}
