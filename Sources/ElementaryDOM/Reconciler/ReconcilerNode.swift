public protocol _Reconcilable: AnyObject {
    func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext)

    func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext)
    func unmount(_ context: inout _CommitContext)
}

public enum _ReconcileOp {
    case startRemoval
    case cancelRemoval
    case markAsMoved
}

final class UnmountTracker {
    var unmountables: [AnyUnmountable] = []
    var removable: Bool = true
}
public struct UnmountParent {
    var tracker: UnmountTracker
    func onUnmount(_ unmountable: some Unmountable) {
        tracker.unmountables.append(AnyUnmountable(unmountable))
    }

    func onRemoval() {
    }
}

public final class _EmptyNode: _Reconcilable {
    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {}

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {}

    public func unmount(_ context: inout _CommitContext) {}
}

// struct AnyReconcilable {
//     private var node: AnyObject
//     private var _apply: (AnyObject) -> (_ReconcileOp, inout _RenderContext) -> Void
//     private var _collectChildren: (AnyObject) -> (inout ContainerLayoutPass, inout _CommitContext) -> Void
//     private var _unmount: (AnyObject) -> (inout _CommitContext) -> Void

//     init<R: _Reconcilable>(_ node: R) {
//         self.node = node
//         self._apply = R.self.apply as! (AnyObject) -> (_ReconcileOp, inout _RenderContext) -> Void
//         self._collectChildren = R.self.collectChildren as! (AnyObject) -> (inout ContainerLayoutPass, inout _CommitContext) -> Void
//         self._unmount = R.self.unmount as! (AnyObject) -> (inout _CommitContext) -> Void
//     }

//     func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
//         _apply(node)(op, &reconciler)
//     }

//     func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
//         _collectChildren(node)(&ops, &context)
//     }

//     func unmount(_ context: inout _CommitContext) {
//         _unmount(node)(&context)
//     }

//     func unwrap<R: _Reconcilable>(as: R.Type = R.self) -> R {
//         unsafeDowncast(node, to: R.self)
//     }
// }

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
