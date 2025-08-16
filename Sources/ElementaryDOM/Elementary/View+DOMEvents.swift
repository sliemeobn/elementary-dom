import Elementary

public extension View {
    consuming func on(_ event: String, handler: @escaping (AnyObject) -> Void) -> _EventHandlingView<Self> {
        _EventHandlingView(wrapped: self, listener: DOMEventListener(event: event, handler: handler))
    }
}

// TODO: make this _ModifiedView a thing
public struct _EventHandlingView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let listener: DOMEventListener

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        context.eventListeners.listeners.append(view.listener)
        return Wrapped._renderView(view.wrapped, context: context)
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        context.eventListeners.listeners.append(view.listener)
        return Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        context.eventListeners.listeners.append(view.listener)
        Wrapped._patchNode(view.wrapped, context: context, node: node, reconciler: &reconciler)
    }
}
