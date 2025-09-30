extension _HTMLConditional: View where TrueContent: View, FalseContent: View {}
extension _HTMLConditional: _Mountable where TrueContent: _Mountable, FalseContent: _Mountable {
    public typealias _MountedNode = _ConditionalNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view.value {
        case let .trueContent(content):
            return .init(a: TrueContent._makeNode(content, context: context, reconciler: &reconciler), context: context)
        case let .falseContent(content):
            return .init(b: FalseContent._makeNode(content, context: context, reconciler: &reconciler), context: context)
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        switch view.value {
        case let .trueContent(content):
            node.patchWithA(
                reconciler: &reconciler,
                makeNode: { c, r in TrueContent._makeNode(content, context: c, reconciler: &r) },
                updateNode: { node, r in TrueContent._patchNode(content, node: node, reconciler: &r) }
            )
        case let .falseContent(content):
            node.patchWithB(
                reconciler: &reconciler,
                makeNode: { c, r in FalseContent._makeNode(content, context: c, reconciler: &r) },
                updateNode: { node, r in FalseContent._patchNode(content, node: node, reconciler: &r) }
            )
        }
    }
}
