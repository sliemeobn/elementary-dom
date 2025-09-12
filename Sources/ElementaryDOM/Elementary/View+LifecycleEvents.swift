import Elementary
import _Concurrency

public extension View {
    // TODO: make rename this to onAppear and onDisappear and reserve mounting lingo for DOM nodes?
    func onMount(_ action: @escaping () -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(wrapped: self, listener: .onMount(action))
    }

    func onUnmount(_ action: @escaping () -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(wrapped: self, listener: .onUnmount(action))
    }

    func task(_ task: @escaping () async -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(
            wrapped: self,
            listener: .onMountReturningCancelFunction({ Task { await task() }.cancel })
        )
    }
}

public struct _LifecycleEventView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    public typealias _MountedNode = _LifecycleNode<Wrapped._MountedNode>

    let wrapped: Wrapped
    let listener: LifecycleHook

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(
            value: view.listener,
            child: Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler),
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        //TODO: should we patch something? maybe update values?
        Wrapped._patchNode(view.wrapped, node: &node.child, reconciler: &reconciler)
    }
}
