// FIXME:NONCOPYABLE this should be ~Copyable once associatedtype is supported (//where NodeA: ~Copyable, NodeB: ~Copyable)
public struct ConditionalNode<NodeA: MountedNode, NodeB: MountedNode> {
    // FIXME:NONCOPYABLE noncopyable enums cannot mutate in-place, making the code very frustrating to write
    // enum State: ~Copyable {
    //     case a(NodeA)
    //     case b(NodeB)
    //     case aWithBLeaving(NodeA, NodeB)
    //     case bWithALeaving(NodeB, NodeA)
    // }

    enum State {
        case a
        case b
        case aWithBLeaving
        case bWithALeaving
    }

    private var a: NodeA?
    private var b: NodeB?

    private var state: State {
        // NOTE: a poor-man's enum with associated values
        didSet {
            switch state {
            case .a:
                precondition(a != nil && b == nil)
            case .b:
                precondition(b != nil && a == nil)
            case .aWithBLeaving:
                precondition(a != nil && b != nil)
            case .bWithALeaving:
                precondition(b != nil && a != nil)
            }
            logTrace("conditional state: \(state)")
        }
    }

    init(a: consuming NodeA) {
        self.a = a
        self.state = .a
    }

    init(b: consuming NodeB) {
        self.b = b
        self.state = .b
    }

    mutating func patchWithA(reconciler: inout _ReconcilerBatch, _ perform: (inout NodeA?, inout _ReconcilerBatch) -> Void) {
        logTrace("patchWithA: \(state)")
        switch state {
        case .a:
            perform(&a, &reconciler)
            state = .a
        case .b:
            b!.startRemoval(&reconciler)
            perform(&a, &reconciler)
            state = .aWithBLeaving
        case .aWithBLeaving:
            perform(&a, &reconciler)
            state = .aWithBLeaving
        case .bWithALeaving:
            perform(&a, &reconciler)
            a!.cancelRemoval(&reconciler)
            b!.startRemoval(&reconciler)
            state = .aWithBLeaving
        }
    }

    mutating func patchWithB(reconciler: inout _ReconcilerBatch, _ perform: (inout NodeB?, inout _ReconcilerBatch) -> Void) {
        logTrace("patchWithB: \(state)")
        switch state {
        case .b:
            perform(&b, &reconciler)
            state = .b
        case .a:
            a!.startRemoval(&reconciler)
            perform(&b, &reconciler)
            state = .bWithALeaving
        case .bWithALeaving:
            perform(&b, &reconciler)
            state = .bWithALeaving
        case .aWithBLeaving:
            perform(&b, &reconciler)
            b!.cancelRemoval(&reconciler)
            a!.startRemoval(&reconciler)
            state = .bWithALeaving
        }
    }
}

extension ConditionalNode: MountedNode {
    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        switch state {
        case .a:
            a!.collectChildren(&ops)
        case .b:
            b!.collectChildren(&ops)
        case .aWithBLeaving:
            a!.collectChildren(&ops)

            let isRemovalCompleted = ops.withRemovalTracking { ops in
                b!.collectChildren(&ops)
            }

            if isRemovalCompleted {
                print("TO BE DONE: unmounting b")
                b = nil
                state = .a
            }
        case .bWithALeaving:
            // NOTE: ordering of a before b is important because we don't want to track moves here
            let isRemovalCompleted = ops.withRemovalTracking { ops in
                a!.collectChildren(&ops)
            }

            b!.collectChildren(&ops)

            if isRemovalCompleted {
                print("TO BE DONE: unmounting a")
                a = nil
                state = .b
            }
        }
    }

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        a?.startRemoval(&reconciler)
        b?.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        a?.cancelRemoval(&reconciler)
        b?.cancelRemoval(&reconciler)
    }
}

extension ContainerLayoutPass {
    mutating func withRemovalTracking(_ block: (inout Self) -> Void) -> Bool {
        let index = entries.count
        block(&self)
        var isRemoved = true
        for entry in entries[index..<entries.count] {
            if entry.kind != .removed {
                isRemoved = false
                break
            }
        }
        print("isRemoved: \(isRemoved)")
        return isRemoved
    }
}
