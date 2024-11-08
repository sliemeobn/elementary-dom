public extension View {
    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self> {
        _EnvironmentView(wrapped: self, key: key, value: value)
    }
}

public struct _EnvironmentView<V, Wrapped: View>: View {
    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let key: EnvironmentValues._Key<V>
    let value: V

    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        context.environment[view.key] = view.value
        return Wrapped._renderView(view.wrapped, context: context)
    }
}
