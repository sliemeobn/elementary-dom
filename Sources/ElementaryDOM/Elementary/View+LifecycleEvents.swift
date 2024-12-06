import Elementary

public extension View {
    func onMount(_ action: @escaping () -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(wrapped: self, listener: .onMount(action))
    }

    func onUnmount(_ action: @escaping () -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(wrapped: self, listener: .onUnmount(action))
    }

    // _Concurrency / Task API not yet available for embedded wasm
    @_unavailableInEmbedded
    func task(_ task: @escaping () async -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(wrapped: self, listener: .task(task))
    }
}

public struct _LifecycleEventView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let listener: _LifecycleHook

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(value:
            .lifecycle(view.listener, Wrapped._renderView(view.wrapped, context: context))
        )
    }
}
