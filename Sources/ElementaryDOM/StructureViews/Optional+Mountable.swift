extension Optional: View where Wrapped: View {}
extension Optional: _Mountable where Wrapped: _Mountable {
    public typealias _MountedNode = _ConditionalNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view {
        case let .some(view):
            return .init(a: Wrapped._makeNode(view, context: context, reconciler: &reconciler), context: context)
        case .none:
            return .init(b: _EmptyNode(), context: context)
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        switch view {
        case let .some(view):
            node.patchWithA(
                reconciler: &reconciler,
                makeNode: { c, r in Wrapped._makeNode(view, context: c, reconciler: &r) },
                updateNode: { node, r in Wrapped._patchNode(view, node: node, reconciler: &r) }
            )
        case .none:
            node.patchWithB(
                reconciler: &reconciler,
                makeNode: { _, _ in _EmptyNode() },
                updateNode: { _, _ in }
            )
        }
    }
}
