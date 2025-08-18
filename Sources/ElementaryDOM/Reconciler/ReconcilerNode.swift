// public enum _ReconcilerNode<DOMInteractor: _DOMInteracting> {
//     case fragment([_ReconcilerNode])
//     case dynamic(Dynamic)
//     case element(Element)
//     case lifecycle(Lifecycle)
//     case text(Text)
//     case function(Function)
//     case nothing

//     func runLayoutPass(_ ops: inout LayoutPass) {
//         switch self {
//         case .fragment(let children):
//             for child in children {
//                 child.runLayoutPass(&ops)
//             }
//         case .dynamic(let dynamic):
//             dynamic.collectLayoutChanges(&ops)
//         case .element(let element):
//             element.domNode.collectLayoutChanges(&ops)
//         case .lifecycle(let lifecycle):
//             lifecycle.child.runLayoutPass(&ops)
//         case .text(let text):
//             text.domNode.collectLayoutChanges(&ops)
//         case .function(let function):
//             function.child.runLayoutPass(&ops)
//         case .nothing:
//             break
//         }
//     }

//     func startRemoval(_ context: inout Reconciler) {

//     }
// }

public protocol MountedNode: ~Copyable {
    mutating func runLayoutPass(_ ops: inout LayoutPass)
    mutating func startRemoval(reconciler: inout _ReconcilerBatch)
}

public struct EmptyNode: MountedNode {
    public mutating func runLayoutPass(_ ops: inout LayoutPass) {}
    public mutating func startRemoval(reconciler: inout _ReconcilerBatch) {}
}
