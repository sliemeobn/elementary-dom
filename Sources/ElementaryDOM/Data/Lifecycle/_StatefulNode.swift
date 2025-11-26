public final class _StatefulNode<State, Child: _Reconcilable> {
    var state: State
    var child: Child
    private var onUnmount: ((inout _CommitContext) -> Void)?

    init(state: State, child: Child) {
        self.state = state
        self.child = child
    }

    private init(state: State, child: Child, onUnmount: ((inout _CommitContext) -> Void)? = nil) {
        self.state = state
        self.child = child
        self.onUnmount = onUnmount
    }

    // generic initializers must be convenience on final classes for embedded wasm
    // https://github.com/swiftlang/swift/issues/78150
    convenience init(state: State, child: Child) where State: Unmountable {
        self.init(state: state, child: child, onUnmount: state.unmount(_:))
    }
}

extension _StatefulNode: _Reconcilable {
    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child.apply(op, &reconciler)
    }

    public func unmount(_ context: inout _CommitContext) {
        child.unmount(&context)
        onUnmount?(&context)
        self.onUnmount = nil
    }
}
