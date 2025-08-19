// FIXME:NONCOPYABLE this should be ~Copyable once associatedtype is supported (//where NodeA: ~Copyable, NodeB: ~Copyable)
public struct ConditionalNode<NodeA: MountedNode, NodeB: MountedNode> {
    var a: NodeA?
    var b: NodeB?
    var state: State

    enum State {
        case a
        case b
        case bLeaving
        case aLeaving
    }

    init(a: consuming NodeA) {
        self.a = consume a
        self.state = .a
    }

    init(b: consuming NodeB) {
        self.b = consume b
        self.state = .b
    }

    mutating func patchWithA(reconciler: inout _ReconcilerBatch, _ perform: (inout NodeA?, inout _ReconcilerBatch) -> Void) {
        switch state {
        case .a:
            perform(&a, &reconciler)
        case .b:
            assert(b != nil)

            state = .bLeaving
            b?.startRemoval(reconciler: &reconciler)

            perform(&a, &reconciler)
        case .bLeaving:
            perform(&a, &reconciler)
        case .aLeaving:
            state = .bLeaving
            b?.startRemoval(reconciler: &reconciler)

            // TODO: cancel removal of a
            perform(&a, &reconciler)
        }
    }

    mutating func patchWithB(reconciler: inout _ReconcilerBatch, _ perform: (inout NodeB?, inout _ReconcilerBatch) -> Void) {
        switch state {
        case .b:
            perform(&b, &reconciler)
        case .a:
            assert(a != nil)

            state = .aLeaving
            a?.startRemoval(reconciler: &reconciler)

            // TODO: cancel removal of b
            perform(&b, &reconciler)
        case .bLeaving:
            state = .aLeaving

            // TODO: cancel removal of b
            a?.startRemoval(reconciler: &reconciler)
            perform(&b, &reconciler)
        case .aLeaving:
            perform(&b, &reconciler)
        }
    }
}

extension ConditionalNode: MountedNode {
    public mutating func runLayoutPass(_ ops: inout ContainerLayoutPass) {
        a?.runLayoutPass(&ops)
        b?.runLayoutPass(&ops)
    }

    public mutating func startRemoval(reconciler: inout _ReconcilerBatch) {
        a?.startRemoval(reconciler: &reconciler)
        b?.startRemoval(reconciler: &reconciler)
    }
}
