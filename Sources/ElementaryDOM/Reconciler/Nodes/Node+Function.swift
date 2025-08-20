public final class Function<ChildNode: MountedNode>: MountedNode where ChildNode: ~Copyable {
    public typealias _ManagedState = AnyObject

    var value: Value
    var state: _ManagedState?
    let parentElement: AnyParentElememnt
    public var depthInTree: Int

    var asFunctionNode: AnyFunctionNode!

    public var identifier: String {
        "\(depthInTree):\(ObjectIdentifier(self).hashValue)"
    }

    var child: ChildNode?

    init(
        state: _ManagedState?,
        value: Value,
        reconciler: inout _ReconcilerBatch
    ) {
        guard let parentElement = reconciler.parentElement else {
            preconditionFailure("function without parent element")
        }

        self.value = value
        self.state = state
        self.parentElement = parentElement
        self.depthInTree = reconciler.depth
        self.asFunctionNode = AnyFunctionNode(self)

        logTrace("added function \(identifier), state: \(state == nil ? "no" : "yes")")

        // we need to break here for scoped reactivity tracking
        reconciler.addFunction(asFunctionNode)
    }

    func patch(_ value: Value, context: inout _ReconcilerBatch) {
        // TOOD: if value has coparing function we can avoid re-running the function
        self.value = value
        context.addFunction(asFunctionNode)
    }

    public func runUpdate(reconciler: inout _ReconcilerBatch) {
        reconciler.depth = depthInTree + 1
        let reportObservedChange = reconciler.scheduler.scheduleFunction

        // TODO: expose cancellation mechanism of reactivity and keep track of it
        // canceling on onmount/recalc maybe important for retain cycles

        logTrace("running patchNode for function \(identifier)")

        reconciler.withCurrentLayoutContainer(parentElement) { context in
            withReactiveTracking {
                value.makeOrPatch(state, &child, &context)
            } onChange: { [reportObservedChange, self] in
                reportObservedChange(asFunctionNode)
            }
        }
    }

    struct Value {
        // TODO: equality checking
        //var makeNode: (_ManagedState?, inout Reconciler) -> Reconciler.Node
        var makeOrPatch: (_ManagedState?, inout ChildNode?, inout _ReconcilerBatch) -> Void
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass) {
        child?.collectChildren(&ops)
    }

    public func startRemoval(_ reconciler: inout _ReconcilerBatch) {
        child?.startRemoval(&reconciler)
    }

    public func cancelRemoval(_ reconciler: inout _ReconcilerBatch) {
        child?.cancelRemoval(&reconciler)
    }
}

extension AnyFunctionNode {
    init(_ function: Function<some MountedNode & ~Copyable>) {
        self.identifier = ObjectIdentifier(function)
        self.depthInTree = function.depthInTree
        self.runUpdate = function.runUpdate
    }
}
