// NOTE: using the correct render function depends on complie-time overload resolution
// it is a bit fragile and won't scale to many more cases, but for now it feels like a good compromise
public extension View {
    internal func makeValue<DOM>(context: _ViewRenderingContext) -> _ReconcilerNode<DOM>.Function.Value {
        .init(
            patchNode: { [self, context] state, node, reconciler in
                Content._patchNode(content, context: context, node: node, reconciler: &reconciler)
            }
        )
    }

    static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .function(
            .init(
                value: view.makeValue(context: context),
                state: nil,
                childNodeFactory: { [context] state, reconciler in
                    Content._makeNode(view.content, context: context, reconciler: &reconciler)
                },
                reconciler: &reconciler
            )
        )
    }

    static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .function(function):
            function.patch(view.makeValue(context: context), context: &reconciler)
        default:
            fatalError("Expected function node, got \(node)")
        }
    }
}

public extension View where Self: _StatefulView {

    internal static func makeValue<DOM>(
        context: consuming _ViewRenderingContext,
        view: consuming Self
    ) -> _ReconcilerNode<DOM>.Function.Value {
        Self.__applyContext(context, to: &view)
        return .init(
            patchNode: { [context] state, node, reconciler in
                Self.__restoreState(state as! _ViewStateStorage, in: &view)
                Content._patchNode(view.content, context: context, node: node, reconciler: &reconciler)
            }
        )
    }

    static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .function(
            .init(
                value: view.makeValue(context: context),
                state: Self.__initializeState(from: view),
                childNodeFactory: { [context] state, reconciler in
                    Content._makeNode(view.content, context: context, reconciler: &reconciler)
                },
                reconciler: &reconciler
            )
        )
    }

    static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .function(function):
            function.patch(view.makeValue(context: context), context: &reconciler)
        default:
            fatalError("Expected function node, got \(node)")
        }
    }
}
