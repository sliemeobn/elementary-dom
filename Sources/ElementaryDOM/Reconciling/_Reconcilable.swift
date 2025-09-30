// TODO: either get rid of this procol entirely, or at least move the apply/collectChildren stuff somewhere out of this
public protocol _Reconcilable: AnyObject {
    func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext)

    func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext)

    // TODO: should this be destroy?
    func unmount(_ context: inout _CommitContext)
}

public enum _ReconcileOp {
    case startRemoval
    case cancelRemoval
    case markAsMoved
}

struct AnyReconcilable {
    private var node: AnyObject
    private var _apply: (_ReconcileOp, inout _RenderContext) -> Void
    private var _collectChildren: (inout ContainerLayoutPass, inout _CommitContext) -> Void
    private var _unmount: (inout _CommitContext) -> Void

    init<R: _Reconcilable>(_ node: R) {
        self.node = node
        self._apply = node.apply(_:_:)
        self._collectChildren = node.collectChildren(_:_:)
        self._unmount = node.unmount(_:)
    }

    // TODO: get rid of all these functions and use environment hooks to participate in whatever each node actually needs
    func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        _apply(op, &reconciler)
    }

    func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        _collectChildren(&ops, &context)
    }

    func unmount(_ context: inout _CommitContext) {
        _unmount(&context)
    }

    func unwrap<R: _Reconcilable>(as: R.Type = R.self) -> R {
        unsafeDowncast(node, to: R.self)
    }
}
