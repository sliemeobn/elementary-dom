// // NOTE: using the correct render function depends on complie-time overload resolution
// // it is a bit fragile and won't scale to many more cases, but for now it feels like a good compromise
// public extension View where _MountedNode == _FunctionNode<Content._MountedNode> {

//     private consuming func makeValue(context: consuming _ViewContext) -> _MountedNode.Value {
//         Self.__applyContext(context, to: &self)
//         return .init(
//             makeOrPatch: { [self, context] state, node, reconciler in
//                 if node != nil {
//                     Content._patchNode(content, context: context, node: &node!, reconciler: &reconciler)
//                 } else {
//                     node = Content._makeNode(content, context: context, reconciler: &reconciler)
//                 }
//             }
//         )
//     }

//     static func _makeNode(
//         _ view: consuming Self,
//         context: consuming _ViewContext,
//         reconciler: inout _RenderContext
//     ) -> _MountedNode {
//         .init(
//             state: nil,
//             value: view.makeValue(context: context),
//             reconciler: &reconciler
//         )
//     }

//     static func _patchNode(
//         _ view: consuming Self,
//         context: consuming _ViewContext,
//         node: inout _MountedNode,
//         reconciler: inout _RenderContext
//     ) {
//         node.patch(view.makeValue(context: context), context: &reconciler)
//     }
// }

public protocol __FunctionView: View {
    associatedtype __ViewState

    static func __initializeState(from view: borrowing Self) -> __ViewState
    static func __restoreState(_ storage: __ViewState, in view: inout Self)

    static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self)

    static func __isEqual(a: borrowing Self, b: borrowing Self) -> Bool
}

public extension __FunctionView {
    static func __isEqual(a: borrowing Self, b: borrowing Self) -> Bool where Self: Equatable {
        a == b
    }

    static func __isEqual(a: borrowing Self, b: Self) -> Bool where Self: BitwiseCopyable {
        withUnsafeBytes(of: a) { aBytes in
            withUnsafeBytes(of: b) { bBytes in
                // TODO: memcmp?
                aBytes.elementsEqual(bBytes)
            }
        }
    }

    static func __isEqual(a: borrowing Self, b: borrowing Self) -> Bool where Self: Equatable & BitwiseCopyable {
        // that is the question.... but I think if explicit equality is provided, we should use it
        a == b
    }

    static func __isEqual(a: borrowing Self, b: borrowing Self) -> Bool {
        false
    }
}

public extension __FunctionView where __ViewState == Void {
    static func __initializeState(from view: borrowing Self) {}
    static func __restoreState(_ storage: __ViewState, in view: inout Self) {}
}

public extension __FunctionView where _MountedNode == _FunctionNode<Self, Self.Content._MountedNode> {

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(
            value: view,
            context: context,
            reconciler: &reconciler
        )
    }

    static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(view, context, context: &reconciler)
    }
}
