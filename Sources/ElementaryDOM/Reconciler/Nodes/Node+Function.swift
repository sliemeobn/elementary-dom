public protocol FunctionNode: AnyObject {
    var identifier: String { get }
    var depthInTree: Int { get }
    func runUpdate(reconciler: inout _ReconcilerBatch)
}

public final class Function<ChildNode: MountedNode>: FunctionNode, MountedNode {
    public func runLayoutPass(_ ops: inout LayoutPass) {
        child?.runLayoutPass(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        child?.startRemoval(reconciler: &reconciler)
    }

    public typealias _ManagedState = AnyObject

    var value: Value
    var state: _ManagedState?
    let parentElement: AnyLayoutContainer
    public var depthInTree: Int

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

        logTrace("added function \(identifier), state: \(state == nil ? "no" : "yes")")

        // we need to break here for scoped reactivity tracking
        reconciler.pendingFunctions.registerFunctionForUpdate(self)
    }

    func patch(_ value: Value, context: inout _ReconcilerBatch) {
        // TOOD: if value has coparing function we can avoid re-running the function
        self.value = value
        context.pendingFunctions.registerFunctionForUpdate(self)
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
            reportObservedChange(self)
        }
    }

    struct Value {
        // TODO: equality checking
        //var makeNode: (_ManagedState?, inout Reconciler) -> Reconciler.Node
        var makeOrPatch: (_ManagedState?, inout ChildNode?, inout _ReconcilerBatch) -> Void
    }
}
