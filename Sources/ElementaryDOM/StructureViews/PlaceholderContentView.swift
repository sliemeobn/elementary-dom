public struct PlaceholderContentView<Value>: View {
    private var makeNodeFn: (borrowing _ViewContext, inout _RenderContext) -> _PlaceholderNode

    init(makeNodeFn: @escaping (borrowing _ViewContext, inout _RenderContext) -> _PlaceholderNode) {
        self.makeNodeFn = makeNodeFn
    }
}

extension PlaceholderContentView: _Mountable {
    public typealias _MountedNode = _PlaceholderNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        view.makeNodeFn(context, &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

public final class _PlaceholderNode: _Reconcilable {
    var node: AnyReconcilable

    init(node: AnyReconcilable) {
        self.node = node
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        node.apply(op, &reconciler)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        node.collectChildren(&ops, &context)
    }

    public func unmount(_ context: inout _CommitContext) {
        // TODO: we should maybe remove ourself from the parent list?
        // or at least prevent updates to unmounted placeholders
        node.unmount(&context)
    }
}
