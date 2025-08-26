public extension View {
    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self> {
        _EnvironmentView(wrapped: self, key: key, value: value)
    }

    consuming func environment<V: ReactiveObject>(_ object: V) -> _EnvironmentView<V, Self> {
        _EnvironmentView(wrapped: self, key: V.environmentKey, value: object)
    }
}

public struct _EnvironmentView<V, Wrapped: View>: View {
    public typealias _MountedNode = Wrapped._MountedNode

    public typealias Tag = Wrapped.Tag
    let wrapped: Wrapped
    let key: EnvironmentValues._Key<V>
    let value: V

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        context.environment[view.key] = view.value
        return Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        context.environment[view.key] = view.value
        Wrapped._patchNode(view.wrapped, context: context, node: &node, reconciler: &reconciler)
    }
}
