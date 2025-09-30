extension View {
    public func transition<T: Transition>(_ transition: T) -> _TransitionView<T, Self> {
        _TransitionView(transition: transition, wrapped: self)
    }
}

public struct _TransitionView<T: Transition, V: View>: View {
    public typealias Content = Never
    var transition: T
    var wrapped: V

    public typealias _MountedNode = _TransitionNode<T, V>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(transition: view.transition, wrapped: view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.update(transition: view.transition, wrapped: view.wrapped, context: &reconciler)
    }
}
