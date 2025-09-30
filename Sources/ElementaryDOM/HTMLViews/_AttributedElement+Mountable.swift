extension _AttributedElement: _Mountable, View where Content: _Mountable {
    public typealias _MountedNode = _StatefulNode<_AttributeModifier, Content._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let attributeModifier = _AttributeModifier(value: view.attributes, upstream: context.modifiers, &reconciler)

        var context = copy context
        context.modifiers[_AttributeModifier.key] = attributeModifier

        return _MountedNode(
            state: attributeModifier,
            child: Content._makeNode(view.content, context: context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view.attributes, &reconciler)

        Content._patchNode(
            view.content,
            node: node.child,
            reconciler: &reconciler
        )
    }
}
