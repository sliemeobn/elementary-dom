public final class Function<ChildNode: MountedNode>: MountedNode where ChildNode: ~Copyable {
    public typealias _ManagedState = AnyObject

    var value: Value
    var state: _ManagedState?
    let parentElement: AnyLayoutContainer
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
        self.value = value
        self.state = state
        self.parentElement = reconciler.parentElement
        self.depthInTree = reconciler.depth
        self.asFunctionNode = AnyFunctionNode(self)

        logTrace("added function \(identifier), state: \(state == nil ? "no" : "yes")")

        // we need to break here for scoped reactivity tracking
        reconciler.pendingFunctions.registerFunctionForUpdate(asFunctionNode)
    }

    func patch(_ value: Value, context: inout _ReconcilerBatch) {
        // TOOD: if value has coparing function we can avoid re-running the function
        self.value = value
        context.pendingFunctions.registerFunctionForUpdate(asFunctionNode)
    }

    public func runUpdate(reconciler: inout _ReconcilerBatch) {
        reconciler.depth = depthInTree + 1
        let reportObservedChange = reconciler.reportObservedChange

        // TODO: expose cancellation mechanism of reactivity and keep track of it
        // canceling on onmount/recalc maybe important for retain cycles

        logTrace("running patchNode for function \(identifier)")

        withReactiveTracking {
            value.makeOrPatch(state, &child, &reconciler)
        } onChange: { [reportObservedChange, self] in
            reportObservedChange(asFunctionNode)
        }
    }

    struct Value {
        // TODO: equality checking
        //var makeNode: (_ManagedState?, inout Reconciler) -> Reconciler.Node
        var makeOrPatch: (_ManagedState?, inout ChildNode?, inout _ReconcilerBatch) -> Void
    }

    public func runLayoutPass(_ ops: inout LayoutPass) {
        child?.runLayoutPass(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        child?.startRemoval(reconciler: &reconciler)
    }
}

extension AnyFunctionNode {
    init(_ function: Function<some MountedNode & ~Copyable>) {
        self.identifier = ObjectIdentifier(function)
        self.depthInTree = function.depthInTree
        self.runUpdate = function.runUpdate
    }
}
