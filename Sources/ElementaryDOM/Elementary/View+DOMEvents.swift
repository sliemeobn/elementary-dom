import Elementary

public extension View {
    consuming func on(_ event: String, handler: @escaping (AnyObject) -> Void) -> _EventHandlingView<Self> {
        _EventHandlingView(wrapped: self, listener: DOMEventListener(event: event, handler: handler))
    }
}

public struct _EventHandlingView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let listener: DOMEventListener

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        context.eventListeners.listeners.append(view.listener)
        return Wrapped._renderView(view.wrapped, context: context)
    }
}
