import Elementary

// TODO: figure out how to type this without runtime reflection
@MainActor
struct EventHandler {
    let event: String
    let handler: @MainActor (AnyObject) -> Void
}

public extension View where Tag: HTMLTrait.Attributes.Global {
    @MainActor
    consuming func on(_ event: String, handler: @MainActor @escaping (AnyObject) -> Void) -> _EventHandlingView<Self> {
        _EventHandlingView(wrapped: self, eventHandler: EventHandler(event: event, handler: handler))
    }
}

public struct _EventHandlingView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let eventHandler: EventHandler

    @MainActor
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        context.eventListeners.listeners.append(view.eventHandler)
        return Wrapped._renderView(view.wrapped, context: context)
    }
}
