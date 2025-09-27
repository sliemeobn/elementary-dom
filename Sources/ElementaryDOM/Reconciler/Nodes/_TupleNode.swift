// FIXME:NONCOPYABLE tuples currently do not support ~Copyable
public final class _TupleNode<each N: _Reconcilable>: _Reconcilable {
    let value: (repeat each N)

    init(_ value: repeat each N) {
        self.value = (repeat each value)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        for value in repeat each value {
            value.collectChildren(&ops, &context)
        }
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        for value in repeat each value {
            value.apply(op, &reconciler)
        }
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        for value in repeat each value {
            value.unmount(&context)
        }
    }
}

public final class _TupleNode2<N0: _Reconcilable, N1: _Reconcilable>: _Reconcilable {
    let value: (N0, N1)

    init(_ n0: N0, _ n1: N1) {
        self.value = (n0, n1)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        value.0.collectChildren(&ops, &context)
        value.1.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        value.0.unmount(&context)
        value.1.unmount(&context)
    }
}

public final class _TupleNode3<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable>: _Reconcilable {
    let value: (N0, N1, N2)

    init(_ n0: N0, _ n1: N1, _ n2: N2) {
        self.value = (n0, n1, n2)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        value.0.collectChildren(&ops, &context)
        value.1.collectChildren(&ops, &context)
        value.2.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        value.0.unmount(&context)
        value.1.unmount(&context)
        value.2.unmount(&context)
    }
}

public final class _TupleNode4<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable, N3: _Reconcilable>: _Reconcilable {
    let value: (N0, N1, N2, N3)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3) {
        self.value = (n0, n1, n2, n3)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        value.0.collectChildren(&ops, &context)
        value.1.collectChildren(&ops, &context)
        value.2.collectChildren(&ops, &context)
        value.3.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        value.0.unmount(&context)
        value.1.unmount(&context)
        value.2.unmount(&context)
        value.3.unmount(&context)
    }
}

public final class _TupleNode5<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable, N3: _Reconcilable, N4: _Reconcilable>:
    _Reconcilable
{
    let value: (N0, N1, N2, N3, N4)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3, _ n4: N4) {
        self.value = (n0, n1, n2, n3, n4)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        value.0.collectChildren(&ops, &context)
        value.1.collectChildren(&ops, &context)
        value.2.collectChildren(&ops, &context)
        value.3.collectChildren(&ops, &context)
        value.4.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
        value.4.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        value.0.unmount(&context)
        value.1.unmount(&context)
        value.2.unmount(&context)
        value.3.unmount(&context)
        value.4.unmount(&context)
    }
}

public final class _TupleNode6<
    N0: _Reconcilable,
    N1: _Reconcilable,
    N2: _Reconcilable,
    N3: _Reconcilable,
    N4: _Reconcilable,
    N5: _Reconcilable
>:
    _Reconcilable
{
    let value: (N0, N1, N2, N3, N4, N5)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3, _ n4: N4, _ n5: N5) {
        self.value = (n0, n1, n2, n3, n4, n5)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        value.0.collectChildren(&ops, &context)
        value.1.collectChildren(&ops, &context)
        value.2.collectChildren(&ops, &context)
        value.3.collectChildren(&ops, &context)
        value.4.collectChildren(&ops, &context)
        value.5.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
        value.4.apply(op, &reconciler)
        value.5.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        value.0.unmount(&context)
        value.1.unmount(&context)
        value.2.unmount(&context)
        value.3.unmount(&context)
        value.4.unmount(&context)
    }
}

// @available(macOS 26, *)
// final class TupleNode<let count: Int> {
//     let values: [count of AnyReconcilable]

//     init(_ values: [count of AnyReconcilable]) {
//         self.values = values
//     }
// }
