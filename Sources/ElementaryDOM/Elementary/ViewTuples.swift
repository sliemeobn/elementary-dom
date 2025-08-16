import Elementary

extension _HTMLTuple2: View where V0: View, V1: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
            ])
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .fragment([
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
        ])
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            V0._patchNode(view.v0, context: copy context, node: children[0], reconciler: &reconciler)
            V1._patchNode(view.v1, context: copy context, node: children[1], reconciler: &reconciler)
        default:
            fatalError("Expected fragment node")
        }
    }
}

extension _HTMLTuple3: View where V0: View, V1: View, V2: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
            ])
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .fragment([
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
        ])
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            V0._patchNode(view.v0, context: copy context, node: children[0], reconciler: &reconciler)
            V1._patchNode(view.v1, context: copy context, node: children[1], reconciler: &reconciler)
            V2._patchNode(view.v2, context: copy context, node: children[2], reconciler: &reconciler)
        default:
            fatalError("Expected fragment node")
        }
    }
}

extension _HTMLTuple4: View where V0: View, V1: View, V2: View, V3: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
            ])
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .fragment([
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler),
        ])
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            V0._patchNode(view.v0, context: copy context, node: children[0], reconciler: &reconciler)
            V1._patchNode(view.v1, context: copy context, node: children[1], reconciler: &reconciler)
            V2._patchNode(view.v2, context: copy context, node: children[2], reconciler: &reconciler)
            V3._patchNode(view.v3, context: copy context, node: children[3], reconciler: &reconciler)
        default:
            fatalError("Expected fragment node")
        }
    }
}

extension _HTMLTuple5: View where V0: View, V1: View, V2: View, V3: View, V4: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
                V4._renderView(view.v4, context: copy context),
            ])
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .fragment([
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler),
            V4._makeNode(view.v4, context: copy context, reconciler: &reconciler),
        ])
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            V0._patchNode(view.v0, context: copy context, node: children[0], reconciler: &reconciler)
            V1._patchNode(view.v1, context: copy context, node: children[1], reconciler: &reconciler)
            V2._patchNode(view.v2, context: copy context, node: children[2], reconciler: &reconciler)
            V3._patchNode(view.v3, context: copy context, node: children[3], reconciler: &reconciler)
            V4._patchNode(view.v4, context: copy context, node: children[4], reconciler: &reconciler)
        default:
            fatalError("Expected fragment node")
        }
    }
}

extension _HTMLTuple6: View where V0: View, V1: View, V2: View, V3: View, V4: View, V5: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
                V4._renderView(view.v4, context: copy context),
                V5._renderView(view.v5, context: copy context),
            ])
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .fragment([
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler),
            V4._makeNode(view.v4, context: copy context, reconciler: &reconciler),
            V5._makeNode(view.v5, context: copy context, reconciler: &reconciler),
        ])
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            V0._patchNode(view.v0, context: copy context, node: children[0], reconciler: &reconciler)
            V1._patchNode(view.v1, context: copy context, node: children[1], reconciler: &reconciler)
            V2._patchNode(view.v2, context: copy context, node: children[2], reconciler: &reconciler)
            V3._patchNode(view.v3, context: copy context, node: children[3], reconciler: &reconciler)
            V4._patchNode(view.v4, context: copy context, node: children[4], reconciler: &reconciler)
            V5._patchNode(view.v5, context: copy context, node: children[5], reconciler: &reconciler)
        default:
            fatalError("Expected fragment node")
        }
    }
}

#if !hasFeature(Embedded)
extension _HTMLTuple: View where repeat each Child: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var renderedChildren: [_RenderedView] = []
        // renderedChildren.reserveCapacity(view.value.count)

        func addChild<C: View>(_ child: consuming sending C) {
            renderedChildren.append(C._renderView(child, context: copy context))
        }

        repeat addChild(each view.value)

        return .init(
            value: .staticList(renderedChildren)
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        var nodes: [_ReconcilerNode<DOM>] = []

        func addChild<C: View>(_ child: consuming sending C) {
            nodes.append(C._makeNode(child, context: copy context, reconciler: &reconciler))
        }

        repeat addChild(each view.value)

        return .fragment(nodes)
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .fragment(children):
            var i = 0
            func patchChild<C: View>(_ child: consuming sending C) {
                C._patchNode(child, context: copy context, node: children[i], reconciler: &reconciler)
                i += 1
            }
            repeat patchChild(each view.value)
        default:
            fatalError("Expected fragment node")
        }
    }
}
#endif
