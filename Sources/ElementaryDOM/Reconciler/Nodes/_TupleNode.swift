// FIXME:NONCOPYABLE tuples currently do not support ~Copyable
public struct _TupleNode<each N: _Reconcilable>: _Reconcilable {
    var value: (repeat each N)

    init(_ value: repeat each N) {
        self.value = (repeat each value)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        for var value in repeat each value {
            value.collectChildren(&ops)
        }
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        for var value in repeat each value {
            value.apply(op, &reconciler)
        }
    }
}

public struct _TupleNode2<N0: _Reconcilable, N1: _Reconcilable>: _Reconcilable {
    var value: (N0, N1)

    init(_ n0: N0, _ n1: N1) {
        self.value = (n0, n1)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
    }
}

public struct _TupleNode3<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable>: _Reconcilable {
    var value: (N0, N1, N2)

    init(_ n0: N0, _ n1: N1, _ n2: N2) {
        self.value = (n0, n1, n2)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
        value.2.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
    }
}

public struct _TupleNode4<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable, N3: _Reconcilable>: _Reconcilable {
    var value: (N0, N1, N2, N3)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3) {
        self.value = (n0, n1, n2, n3)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
        value.2.collectChildren(&ops)
        value.3.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
    }
}

public struct _TupleNode5<N0: _Reconcilable, N1: _Reconcilable, N2: _Reconcilable, N3: _Reconcilable, N4: _Reconcilable>:
    _Reconcilable
{
    var value: (N0, N1, N2, N3, N4)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3, _ n4: N4) {
        self.value = (n0, n1, n2, n3, n4)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
        value.2.collectChildren(&ops)
        value.3.collectChildren(&ops)
        value.4.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
        value.4.apply(op, &reconciler)
    }
}

public struct _TupleNode6<
    N0: _Reconcilable,
    N1: _Reconcilable,
    N2: _Reconcilable,
    N3: _Reconcilable,
    N4: _Reconcilable,
    N5: _Reconcilable
>:
    _Reconcilable
{
    var value: (N0, N1, N2, N3, N4, N5)

    init(_ n0: N0, _ n1: N1, _ n2: N2, _ n3: N3, _ n4: N4, _ n5: N5) {
        self.value = (n0, n1, n2, n3, n4, n5)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
        value.2.collectChildren(&ops)
        value.3.collectChildren(&ops)
        value.4.collectChildren(&ops)
        value.5.collectChildren(&ops)
    }

    public mutating func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        value.0.apply(op, &reconciler)
        value.1.apply(op, &reconciler)
        value.2.apply(op, &reconciler)
        value.3.apply(op, &reconciler)
        value.4.apply(op, &reconciler)
        value.5.apply(op, &reconciler)
    }
}
