// NOTE: using the correct render function depends on complie-time overload resolution
// it is a bit fragile and won't scale to many more cases, but for now it feels like a good compromise
public extension View where Node == Function<Content.Node> {

    private consuming func makeValue(context: consuming _ViewRenderingContext) -> Node.Value {
        .init(
            makeOrPatch: { [self, context] state, node, reconciler in
                if node != nil {
                    Content._patchNode(content, context: context, node: &node!, reconciler: &reconciler)
                } else {
                    node = Content._makeNode(content, context: context, reconciler: &reconciler)
                }
            }
        )
    }

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        .init(
            state: nil,
            value: view.makeValue(context: context),
            reconciler: &reconciler
        )
    }

    static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        node.patch(view.makeValue(context: context), context: &reconciler)
    }
}

public extension _StatefulView where Node == Function<Content.Node> {
    private consuming func makeValue(
        context: consuming _ViewRenderingContext,
    ) -> Node.Value {
        Self.__applyContext(context, to: &self)
        return .init(
            makeOrPatch: { [context] state, node, reconciler in
                Self.__restoreState(state as! _ViewStateStorage, in: &self)
                if node != nil {
                    Content._patchNode(self.content, context: context, node: &node!, reconciler: &reconciler)
                } else {
                    node = Content._makeNode(self.content, context: context, reconciler: &reconciler)
                }
            }
        )
    }

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        .init(
            state: Self.__initializeState(from: view),
            value: view.makeValue(context: context),
            reconciler: &reconciler
        )
    }

    static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        node.patch(view.makeValue(context: context), context: &reconciler)
    }
}
