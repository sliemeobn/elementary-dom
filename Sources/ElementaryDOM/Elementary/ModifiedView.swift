struct _ModifiedView<V: View>: View {
    public typealias Node = V.Node

    let wrapped: V
    let modifier: (inout _ViewRenderingContext) -> Void

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        view.modifier(&context)
        return V._makeNode(view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        view.modifier(&context)
        V._patchNode(view.wrapped, context: context, node: &node, reconciler: &reconciler)
    }
}
