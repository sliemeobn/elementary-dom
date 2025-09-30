extension HTMLElement: _Mountable, View where Content: _Mountable {
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
                makeChild: { viewContext, r in AnyReconcilable(Content._makeNode(view.content, context: viewContext, reconciler: &r)) }
            )
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view._attributes, &reconciler)

        node.child.updateChild(&reconciler, as: Content._MountedNode.self) { child, r in
            Content._patchNode(
                view.content,
                node: child,
                reconciler: &r
            )
        }
    }
}
