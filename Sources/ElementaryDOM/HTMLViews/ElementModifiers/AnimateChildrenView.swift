import Elementary

struct AnimateContainerLayoutView<Wrapped: View>: View {
    typealias Tag = Wrapped.Tag
    typealias _MountedNode = _StatefulNode<FLIPLayoutObserver, Wrapped._MountedNode>

    var animateContainerSize: Bool = true
    var wrapped: Wrapped

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {

        let observer = FLIPLayoutObserver(
            animateContainerSize: view.animateContainerSize
        )

        var context = copy context
        context.layoutObservers.add(observer)

        return _MountedNode(
            state: observer,
            child: Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)
        )
    }

    static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.update(animateContainerSize: view.animateContainerSize)
        Wrapped._patchNode(view.wrapped, node: node.child, reconciler: &reconciler)
    }
}

public extension View {
    func animateContainerLayout(
        animateContainerSize: Bool = true
    ) -> some View<Self.Tag> {
        AnimateContainerLayoutView(
            animateContainerSize: animateContainerSize,
            wrapped: self
        )
    }
}
