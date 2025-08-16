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
        .init(
            value:
                .lifecycle(view.listener, Wrapped._renderView(view.wrapped, context: context))
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .lifecycle(.init(value: view.listener, child: Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)))
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .lifecycle(lifecycle):
            //TODO: should we patch something? maybe update values?
            Wrapped._patchNode(view.wrapped, context: context, node: lifecycle.child, reconciler: &reconciler)
        default:
            fatalError("Expected lifecycle node, got \(node)")
        }
    }
}
