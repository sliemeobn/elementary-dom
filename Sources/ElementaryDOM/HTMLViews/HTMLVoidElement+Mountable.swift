extension HTMLVoidElement: _Mountable, View {
    public typealias _MountedNode = _StatefulNode<_AttributeModifier, _ElementNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let attributeModifier = _AttributeModifier(value: view._attributes, upstream: context.modifiers, &reconciler)

        var context = copy context
        context.modifiers[_AttributeModifier.key] = attributeModifier

        return _MountedNode(
            state: attributeModifier,
            child: _ElementNode(
                tag: self.Tag.name,
                viewContext: context,
                context: &reconciler,
                makeChild: { _, _ in AnyReconcilable(_EmptyNode()) }
            )
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view._attributes, &reconciler)
    }
}
