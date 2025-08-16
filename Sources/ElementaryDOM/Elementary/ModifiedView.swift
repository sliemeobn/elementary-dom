struct _ModifiedView<V: View>: View {
    let wrapped: V
    let modifier: (inout _ViewRenderingContext) -> Void

    static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        view.modifier(&context)
        return V._makeNode(view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        view.modifier(&context)
        V._patchNode(view.wrapped, context: context, node: node, reconciler: &reconciler)
    }
}
