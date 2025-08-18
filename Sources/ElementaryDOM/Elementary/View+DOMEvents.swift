import Elementary

public extension View {
    consuming func on(_ event: String, handler: @escaping (DOM.Event) -> Void) -> _EventHandlingView<Self> {
        _EventHandlingView(wrapped: self, listener: DOMEventListener(event: event, handler: handler))
    }
}

// TODO: make this _ModifiedView a thing
public struct _EventHandlingView<Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    public typealias Node = Wrapped.Node

    let wrapped: Wrapped
    let listener: DOMEventListener

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        context.eventListeners.listeners.append(view.listener)
        return Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        context.eventListeners.listeners.append(view.listener)
        Wrapped._patchNode(view.wrapped, context: context, node: &node, reconciler: &reconciler)
    }
}
