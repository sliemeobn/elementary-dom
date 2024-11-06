public protocol _StatefulView: View {
    static func _initializeState(from view: borrowing Self) -> _ViewStateStorage
    static func _restoreState(_ storage: _ViewStateStorage, in view: inout Self)
}

public extension _StatefulView {
    static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(value: .function(.from(view, context: context)))
    }
}

extension _RenderFunction {
    static func from<V: _StatefulView>(_ view: sending V, context: consuming _ViewRenderingContext) -> _RenderFunction {
        return .init(
            initializeState: { V._initializeState(from: view) },
            getContent: { [context] state in
                V._restoreState(state!, in: &view)
                return V.Content._renderView(view.content, context: context)
            }
        )
    }
}
