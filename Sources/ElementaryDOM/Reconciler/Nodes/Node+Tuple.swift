// FIXME:NONCOPYABLE tuples currently do not support ~Copyable
public struct TupleNode<each N: MountedNode>: MountedNode {
    var value: (repeat each N)

    init(_ value: repeat each N) {
        self.value = (repeat each value)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        for var value in repeat each value {
            value.collectChildren(&ops)
        }
    }

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        for var value in repeat each value {
            value.startRemoval(&reconciler)
        }
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        for var value in repeat each value {
            value.cancelRemoval(&reconciler)
        }
    }
}

public struct TupleNode2<N0: MountedNode, N1: MountedNode>: MountedNode {
    var value: (N0, N1)

    init(_ n0: N0, _ n1: N1) {
        self.value = (n0, n1)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
    }

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.startRemoval(&reconciler)
        value.1.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.cancelRemoval(&reconciler)
        value.1.cancelRemoval(&reconciler)
    }
}

public struct TupleNode3<N0: MountedNode, N1: MountedNode, N2: MountedNode>: MountedNode {
    var value: (N0, N1, N2)

    init(_ n0: N0, _ n1: N1, _ n2: N2) {
        self.value = (n0, n1, n2)
    }

    public mutating func collectChildren(_ ops: inout ContainerLayoutPass) {
        value.0.collectChildren(&ops)
        value.1.collectChildren(&ops)
        value.2.collectChildren(&ops)
    }

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.startRemoval(&reconciler)
        value.1.startRemoval(&reconciler)
        value.2.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.cancelRemoval(&reconciler)
        value.1.cancelRemoval(&reconciler)
        value.2.cancelRemoval(&reconciler)
    }
}

public struct TupleNode4<N0: MountedNode, N1: MountedNode, N2: MountedNode, N3: MountedNode>: MountedNode {
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

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.startRemoval(&reconciler)
        value.1.startRemoval(&reconciler)
        value.2.startRemoval(&reconciler)
        value.3.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.cancelRemoval(&reconciler)
        value.1.cancelRemoval(&reconciler)
        value.2.cancelRemoval(&reconciler)
        value.3.cancelRemoval(&reconciler)
    }
}

public struct TupleNode5<N0: MountedNode, N1: MountedNode, N2: MountedNode, N3: MountedNode, N4: MountedNode>: MountedNode {
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

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.startRemoval(&reconciler)
        value.1.startRemoval(&reconciler)
        value.2.startRemoval(&reconciler)
        value.3.startRemoval(&reconciler)
        value.4.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.cancelRemoval(&reconciler)
        value.1.cancelRemoval(&reconciler)
        value.2.cancelRemoval(&reconciler)
        value.3.cancelRemoval(&reconciler)
        value.4.cancelRemoval(&reconciler)
    }
}

public struct TupleNode6<N0: MountedNode, N1: MountedNode, N2: MountedNode, N3: MountedNode, N4: MountedNode, N5: MountedNode>: MountedNode
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

    public mutating func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.startRemoval(&reconciler)
        value.1.startRemoval(&reconciler)
        value.2.startRemoval(&reconciler)
        value.3.startRemoval(&reconciler)
        value.4.startRemoval(&reconciler)
        value.5.startRemoval(&reconciler)
    }

    public mutating func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        value.0.cancelRemoval(&reconciler)
        value.1.cancelRemoval(&reconciler)
        value.2.cancelRemoval(&reconciler)
        value.3.cancelRemoval(&reconciler)
        value.4.cancelRemoval(&reconciler)
        value.5.cancelRemoval(&reconciler)
    }
}
