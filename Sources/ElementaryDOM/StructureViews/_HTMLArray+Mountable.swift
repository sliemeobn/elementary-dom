extension _HTMLArray: _Mountable, View where Element: View {
    public typealias _MountedNode = _KeyedNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            view.value.enumerated().map { (index, element) in
                (
                    key: _ViewKey(String(index)),
                    node: Element._makeNode(element, context: context, reconciler: &reconciler)
                )
            },
            context: context
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        // maybe we can optimize this
        // NOTE: written with cast for this https://github.com/swiftlang/swift/issues/83895
        let indexes = view.value.indices.map { _ViewKey(String($0 as Int)) }

        node.patch(
            indexes,
            context: &reconciler,
            as: Element._MountedNode.self,
            makeOrPatchNode: { index, node, context, r in
                if node == nil {
                    node = Element._makeNode(view.value[index], context: context, reconciler: &r)
                } else {
                    Element._patchNode(view.value[index], node: node!, reconciler: &r)
                }
            }
        )

    }
}
