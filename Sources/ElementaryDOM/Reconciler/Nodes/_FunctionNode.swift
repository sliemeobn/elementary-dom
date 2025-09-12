// TODO: find a better name for this, "function node" is weird terminology

// NOTE: ChildNode must be specified as extra argument to avoid a compiler error in embedded
// FIXME: embedded - try with embedded main-snapshot build, revert extra argument if it works
public final class _FunctionNode<Value, ChildNode>
where Value: __FunctionView, ChildNode: _Reconcilable, ChildNode == Value.Content._MountedNode {
    private var state: Value.__ViewState?
    private var value: Value?
    private var context: _ViewContext?

    var parentElement: AnyParentElememnt!
    public var depthInTree: Int

    var asFunctionNode: AnyFunctionNode!

    public var identifier: String {
        "\(depthInTree):\(ObjectIdentifier(self).hashValue)"
    }

    var child: Value.Content._MountedNode?

    init(
        value: consuming Value,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) {
        guard let parentElement = reconciler.parentElement else {
            preconditionFailure("function without parent element")
        }

        self.parentElement = parentElement
        self.depthInTree = reconciler.depth

        self.state = Value.__initializeState(from: value)
        Value.__applyContext(context, to: &value)
        Value.__restoreState(state!, in: &value)
        self.value = value
        self.context = copy context

        self.asFunctionNode = AnyFunctionNode(self)

        logTrace("added function \(identifier)")

        // we need to break here for scoped reactivity tracking
        reconciler.addFunction(asFunctionNode)
    }

    func patch(_ value: consuming Value, context: inout _RenderContext) {
        precondition(self.value != nil, "value must be set")
        precondition(self.context != nil, "context must be set")

        let needsRerender = !Value.__areEqual(a: value, b: self.value!)

        // NOTE: the idea is that way always store a "wired-up" value, so that we can re-run the function for free
        Value.__applyContext(self.context!, to: &value)
        Value.__restoreState(state!, in: &value)
        self.value = value

        if needsRerender {
            context.addFunction(asFunctionNode)
        }
    }

    func runFunction(reconciler: inout _RenderContext) {
        logTrace("running function \(identifier)")
        reconciler.depth = depthInTree + 1

        precondition(self.value != nil, "value must be set")
        precondition(self.context != nil, "context must be set")

        // TODO: expose cancellation mechanism of reactivity and keep track of it
        // canceling on unmount/recalc maybe important for retain cycles

        reconciler.withCurrentLayoutContainer(parentElement) { reconciler in
            withReactiveTracking {
                if child == nil {
                    self.child = Value.Content._makeNode(self.value!.content, context: context!, reconciler: &reconciler)
                } else {
                    Value.Content._patchNode(self.value!.content, node: &child!, reconciler: &reconciler)
                }
            } onChange: { [scheduler = reconciler.scheduler, asFunctionNode = asFunctionNode!] in
                scheduler.scheduleFunction(asFunctionNode)
            }
        }
    }
}

extension _FunctionNode: _Reconcilable {

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        child?.collectChildren(&ops, &context)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        child?.apply(op, &reconciler)
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        let c = self.child.take()
        c?.unmount(&context)

        self.state = nil
        self.value = nil
        self.context = nil
        self.parentElement = nil
    }
}

extension AnyFunctionNode {
    init(_ function: _FunctionNode<some __FunctionView, some _Reconcilable>) {
        self.identifier = ObjectIdentifier(function)
        self.depthInTree = function.depthInTree
        self.runUpdate = function.runFunction
    }
}
