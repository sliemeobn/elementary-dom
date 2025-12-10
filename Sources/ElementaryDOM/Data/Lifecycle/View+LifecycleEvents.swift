import _Concurrency

public extension View {
    /// Adds an action to perform after this view appears.
    ///
    /// Use this modifier to run code when a view is first mounted in the DOM.
    /// This is useful for initializing state, starting timers, or setting up
    /// external resources.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// div { "Hello, world!" }
    ///     .onMount {
    ///         print("View mounted")
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure to execute after the view appears.
    /// - Returns: A view that performs the action on mount.
    func onMount(_ action: @escaping () -> Void) -> some View<Tag> {
        _LifecycleEventView(wrapped: self, listener: .onMount(action))
    }

    /// Adds an action to perform when this view disappears.
    ///
    /// Use this modifier to run cleanup code when a view is removed from the DOM.
    /// This is useful for releasing resources, canceling timers, or removing listeners.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// div { "Temporary content" }
    ///     .onUnmount {
    ///         print("View removed")
    ///         cleanupResources()
    ///     }
    /// ```
    ///
    /// - Parameter action: A closure to execute before the view disappears.
    /// - Returns: A view that performs the action on unmount.
    func onUnmount(_ action: @escaping () -> Void) -> some View<Tag> {
        _LifecycleEventView(wrapped: self, listener: .onUnmount(action))
    }

    /// Adds an asynchronous task to perform after this view appears.
    ///
    /// Use this modifier to run async operations when a view appears. The task
    /// is automatically cancelled when the view is removed.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// @View
    /// struct UserProfile {
    ///     @State var user: User?
    ///
    ///     var body: some View {
    ///         div {
    ///             if let user {
    ///                 p { user.name }
    ///             } else {
    ///                 p { "Loading..." }
    ///             }
    ///         }
    ///         .task {
    ///             user = await fetchUser()
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter task: An async closure to execute when the view appears.
    ///   The task is cancelled when the view disappears.
    /// - Returns: A view that performs the task on mount and cancels it on unmount.
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
