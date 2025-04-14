// trying to stay embedded swift compatible eventually
public typealias _ManagedState = AnyObject

// TODO: better name
public struct _RenderFunction {
    // TODO: think about equality checking or short-circuiting unchanged stuff
    var initializeState: (() -> _ManagedState)?
    var getContent: (_ state: _ManagedState?) -> _RenderedView

    public init(initializeState: (() -> _ManagedState)?, getContent: @escaping (_ state: _ManagedState?) -> _RenderedView) {
        self.initializeState = initializeState
        self.getContent = getContent
    }
}

extension _RenderFunction {
    static func from<V: View>(_ view: consuming sending V, context: _ViewRenderingContext) -> _RenderFunction {
        .init(
            initializeState: nil,
            getContent: { [view] _ in V.Content._renderView(view.content, context: context) }
        )
    }

    static func from<V: _StatefulView>(_ view: sending V, context: consuming _ViewRenderingContext) -> _RenderFunction {
        .init(
            initializeState: { V.__initializeState(from: view) },
            getContent: { [context] state in
                V.__restoreState(state as! _ViewStateStorage, in: &view)
                return V.Content._renderView(view.content, context: context)
            }
        )
    }
}

// NOTE: using the correct render function depends on complie-time overload resolution
// it is a bit fragile and won't scale to many more cases, but for now it feels like a good compromise
public extension View {
    static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        __applyContext(context, to: &view)
        return .init(value: .function(.from(view, context: context)))
    }
}

public extension View where Self: _StatefulView {
    static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        __applyContext(context, to: &view)
        return .init(value: .function(.from(view, context: context)))
    }
}
