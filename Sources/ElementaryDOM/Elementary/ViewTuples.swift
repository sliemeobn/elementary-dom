import Elementary

extension _HTMLTuple2: View where V0: View, V1: View {}
extension _HTMLTuple2: _Mountable where V0: _Mountable, V1: _Mountable {
    public typealias _MountedNode = _TupleNode2<V0._MountedNode, V1._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        V0._patchNode(view.v0, node: &node.value.0, reconciler: &reconciler)
        V1._patchNode(view.v1, node: &node.value.1, reconciler: &reconciler)
    }
}

extension _HTMLTuple3: View where V0: View, V1: View, V2: View {}
extension _HTMLTuple3: _Mountable where V0: _Mountable, V1: _Mountable, V2: _Mountable {
    public typealias _MountedNode = _TupleNode3<V0._MountedNode, V1._MountedNode, V2._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        V0._patchNode(view.v0, node: &node.value.0, reconciler: &reconciler)
        V1._patchNode(view.v1, node: &node.value.1, reconciler: &reconciler)
        V2._patchNode(view.v2, node: &node.value.2, reconciler: &reconciler)
    }
}

extension _HTMLTuple4: View where V0: View, V1: View, V2: View, V3: View {}
extension _HTMLTuple4: _Mountable where V0: _Mountable, V1: _Mountable, V2: _Mountable, V3: _Mountable {
    public typealias _MountedNode = _TupleNode4<V0._MountedNode, V1._MountedNode, V2._MountedNode, V3._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        V0._patchNode(view.v0, node: &node.value.0, reconciler: &reconciler)
        V1._patchNode(view.v1, node: &node.value.1, reconciler: &reconciler)
        V2._patchNode(view.v2, node: &node.value.2, reconciler: &reconciler)
        V3._patchNode(view.v3, node: &node.value.3, reconciler: &reconciler)
    }
}

extension _HTMLTuple5: View where V0: View, V1: View, V2: View, V3: View, V4: View {}
extension _HTMLTuple5: _Mountable where V0: _Mountable, V1: _Mountable, V2: _Mountable, V3: _Mountable, V4: _Mountable {
    public typealias _MountedNode = _TupleNode5<V0._MountedNode, V1._MountedNode, V2._MountedNode, V3._MountedNode, V4._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler),
            V4._makeNode(view.v4, context: copy context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        V0._patchNode(view.v0, node: &node.value.0, reconciler: &reconciler)
        V1._patchNode(view.v1, node: &node.value.1, reconciler: &reconciler)
        V2._patchNode(view.v2, node: &node.value.2, reconciler: &reconciler)
        V3._patchNode(view.v3, node: &node.value.3, reconciler: &reconciler)
        V4._patchNode(view.v4, node: &node.value.4, reconciler: &reconciler)
    }
}

extension _HTMLTuple6: View where V0: View, V1: View, V2: View, V3: View, V4: View, V5: View {}
extension _HTMLTuple6: _Mountable where V0: _Mountable, V1: _Mountable, V2: _Mountable, V3: _Mountable, V4: _Mountable, V5: _Mountable {
    public typealias _MountedNode = _TupleNode6<
        V0._MountedNode, V1._MountedNode, V2._MountedNode, V3._MountedNode, V4._MountedNode, V5._MountedNode
    >

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            V0._makeNode(view.v0, context: copy context, reconciler: &reconciler),
            V1._makeNode(view.v1, context: copy context, reconciler: &reconciler),
            V2._makeNode(view.v2, context: copy context, reconciler: &reconciler),
            V3._makeNode(view.v3, context: copy context, reconciler: &reconciler),
            V4._makeNode(view.v4, context: copy context, reconciler: &reconciler),
            V5._makeNode(view.v5, context: copy context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        V0._patchNode(view.v0, node: &node.value.0, reconciler: &reconciler)
        V1._patchNode(view.v1, node: &node.value.1, reconciler: &reconciler)
        V2._patchNode(view.v2, node: &node.value.2, reconciler: &reconciler)
        V3._patchNode(view.v3, node: &node.value.3, reconciler: &reconciler)
        V4._patchNode(view.v4, node: &node.value.4, reconciler: &reconciler)
        V5._patchNode(view.v5, node: &node.value.5, reconciler: &reconciler)
    }
}

#if !hasFeature(Embedded)
// Generic variadic tuple support using parameter packs
extension _HTMLTuple: View where repeat each Child: View {}
extension _HTMLTuple: _Mountable where repeat each Child: _Mountable {
    public typealias _MountedNode = _TupleNode<repeat (each Child)._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            repeat makeNode(
                each view.value,
                context: copy context,
                reconciler: &reconciler
            )
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        // I don't think there is a way to spell this currently without warnings
        for var (view, node) in repeat (each view.value, each node.value) {
            __noop_goshDarnValuePacksAreAnnoyingAF(&view)  // this is to suppress a warning
            patchNode(view, node: &node, reconciler: &reconciler)
        }

        // NOTE: this doesn't work because I don't think we can pass a value pack as inout
        // repeat patchNode(
        //     each view.value,
        //     context: copy context,
        //     node: each &node.value,
        //     reconciler: &reconciler
        // )

    }
}

@inline(__always)
private func __noop_goshDarnValuePacksAreAnnoyingAF(_ v: inout some _Mountable) {
    // FIXME (once possible)
}

private func makeNode<V: _Mountable>(
    _ view: consuming V,
    context: borrowing _ViewContext,
    reconciler: inout _RenderContext
) -> V._MountedNode {
    V._makeNode(view, context: context, reconciler: &reconciler)
}

private func patchNode<V: _Mountable>(
    _ view: consuming V,
    node: inout V._MountedNode,
    reconciler: inout _RenderContext
) {
    V._patchNode(view, node: &node, reconciler: &reconciler)
}
#endif

// func patch<each V: _Mountable>(
//     _ views: (repeat each V),
//     _ nodes: (repeat (each V).Node),
//     context: consuming _ViewRenderingContext,
//     reconciler: inout _ReconcilerBatch
// ) {
//     for var (view, node) in repeat (each views, each nodes) {
//         patch(view, context: context, node: &node, reconciler: &reconciler)
//     }
// }

// func patch<V: _Mountable>(_ v: V, context: consuming _ViewRenderingContext, node: inout V.Node, reconciler: inout _ReconcilerBatch) {
//     V._patchNode(v, context: context, node: &node, reconciler: &reconciler)
// }
