extension HTMLText: _Mountable, View {
    public typealias _MountedNode = _TextNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(view.text, viewContext: context, context: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(view.text, context: &reconciler)
    }
}
