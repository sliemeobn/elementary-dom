// FIXME:NONCOPYABLE this should be ~Copyable once associatedtype is supported (//where NodeA: ~Copyable, NodeB: ~Copyable)
public final class _ConditionalNode<NodeA: _Reconcilable, NodeB: _Reconcilable> {
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
    private var context: _ViewContext

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
        }
    }

    init(a: consuming NodeA, context: borrowing _ViewContext) {
        self.a = a
        self.state = .a
        self.context = copy context
    }

    init(b: consuming NodeB, context: borrowing _ViewContext) {
        self.b = b
        self.state = .b
        self.context = copy context
    }

    func patchWithA(
        reconciler: inout _RenderContext,
        _ perform: (inout NodeA?, consuming _ViewContext, inout _RenderContext) -> Void
    ) {
        switch state {
        case .a:
            perform(&a, context, &reconciler)
            state = .a
        case .b:
            perform(&a, context, &reconciler)
            b!.apply(.startRemoval, &reconciler)
            reconciler.parentElement?.reportChangedChildren(.elementChanged, &reconciler)
            state = .aWithBLeaving
        case .aWithBLeaving:
            perform(&a, context, &reconciler)
            state = .aWithBLeaving
        case .bWithALeaving:
            perform(&a, context, &reconciler)
            a!.apply(.cancelRemoval, &reconciler)
            b!.apply(.startRemoval, &reconciler)
            reconciler.parentElement?.reportChangedChildren(.elementChanged, &reconciler)
            state = .aWithBLeaving
        }
    }

    func patchWithB(
        reconciler: inout _RenderContext,
        _ perform: (inout NodeB?, consuming _ViewContext, inout _RenderContext) -> Void
    ) {
        switch state {
        case .b:
            perform(&b, context, &reconciler)
            state = .b
        case .a:
            a!.apply(.startRemoval, &reconciler)
            reconciler.parentElement?.reportChangedChildren(.elementChanged, &reconciler)
            perform(&b, context, &reconciler)
            state = .bWithALeaving
        case .bWithALeaving:
            perform(&b, context, &reconciler)
            state = .bWithALeaving
        case .aWithBLeaving:
            perform(&b, context, &reconciler)
            b!.apply(.cancelRemoval, &reconciler)
            a!.apply(.startRemoval, &reconciler)
            reconciler.parentElement?.reportChangedChildren(.elementChanged, &reconciler)
            state = .bWithALeaving
        }
    }
}

extension _ConditionalNode: _Reconcilable {
    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        switch state {
        case .a:
            a!.collectChildren(&ops, &context)
        case .b:
            b!.collectChildren(&ops, &context)
        case .aWithBLeaving:
            a!.collectChildren(&ops, &context)

            let isRemovalCompleted = ops.withRemovalTracking { ops in
                b!.collectChildren(&ops, &context)
            }

            if isRemovalCompleted {
                b!.unmount(&context)
                b = nil
                state = .a
            }
        case .bWithALeaving:
            // NOTE: ordering of a before b is important because we don't want to track moves here
            let isRemovalCompleted = ops.withRemovalTracking { ops in
                a!.collectChildren(&ops, &context)
            }

            b!.collectChildren(&ops, &context)

            if isRemovalCompleted {
                a!.unmount(&context)
                a = nil
                state = .b
            }
        }
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        a?.apply(op, &reconciler)
        b?.apply(op, &reconciler)
    }

    public func unmount(_ context: inout _CommitContext) {
        a?.unmount(&context)
        b?.unmount(&context)
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
        return isRemoved
    }
}
