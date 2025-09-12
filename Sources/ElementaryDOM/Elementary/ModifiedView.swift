// struct _ModifiedView<V: View>: View {
//     public typealias _MountedNode = V._MountedNode

//     let wrapped: V
//     let modifier: (inout _ViewContext) -> Void

//     static func _makeNode(
//         _ view: consuming Self,
//         context: borrowing _ViewContext,
//         reconciler: inout _RenderContext
//     ) -> _MountedNode {
//         view.modifier(&context)
//         return V._makeNode(view.wrapped, context: context, reconciler: &reconciler)
//     }

//     public static func _patchNode(
//         _ view: consuming Self,
//         context: borrowing _ViewContext,
//         node: inout _MountedNode,
//         reconciler: inout _RenderContext
//     ) {
//         view.modifier(&context)
//         V._patchNode(view.wrapped, node: &node, reconciler: &reconciler)
//     }
// }
