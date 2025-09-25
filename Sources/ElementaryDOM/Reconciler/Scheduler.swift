// TODO: this ain't such a great shape...
final class Scheduler {
    private var dom: any DOM.Interactor
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()
    private var runningAnimations: [AnyAnimatable] = []

    private var nodes: [CommitAction] = []
    private var placements: [CommitAction] = []

    private var isAnimationFramePending: Bool = false

    private var currentTransaction: Transaction?
    private var currentFrameTime: Double = 0

    // TODO: this is a bit hacky, ideally we can use explicit depencies on Environment
    private var ambientRenderContext: _RenderContext?

    var needsFrame: Bool { !nodes.isEmpty || !placements.isEmpty || !runningAnimations.isEmpty }

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    func scheduleFunction(_ function: AnyFunctionNode) {
        // NOTE: this is a bit of a hack to scheduel function in the same reconciler run if environment values change
        // we currently uses the same Reactivity tracking for environment changes, but they always happen during reconciliation
        guard ambientRenderContext == nil else {
            ambientRenderContext!.addFunction(function)
            return
        }

        if pendingFunctionsQueue.isEmpty {
            currentTransaction = Transaction._current

            dom.queueMicrotask { [self] in
                self.reconcileTransaction()
            }
        } else if currentTransaction?._id != Transaction._current?._id {
            // in-line a reconcile run if the transaction has changed
            reconcileTransaction()
            currentTransaction = Transaction._current
        }

        pendingFunctionsQueue.registerFunctionForUpdate(function)
    }

    func registerAnimation(_ node: AnyAnimatable) {
        runningAnimations.append(node)
        scheduleFrameIfNecessary()
    }

    func addNodeAction(_ action: CommitAction) {
        nodes.append(action)
    }

    func addPlacementAction(_ action: CommitAction) {
        placements.append(action)
    }

    func withAmbientRenderContext(_ context: inout _RenderContext, _ block: () -> Void) {
        precondition(ambientRenderContext == nil, "ambient reconciliation already exists")
        ambientRenderContext = consume context
        block()
        context = ambientRenderContext.take()!
    }

    private func reconcileTransaction() {
        // frame time is set to 0 on every paint, first reconcile after raf established the time
        updateFrameTimeIfNecessary()

        // TODO: this is awkward, refactor the reconciler API
        var functions = PendingFunctionQueue()
        swap(&pendingFunctionsQueue, &functions)

        _RenderContext(
            scheduler: self,
            currentTime: currentFrameTime,
            transaction: self.currentTransaction,
            pendingFunctions: consume functions,
        ).drain()

        scheduleFrameIfNecessary()
    }

    private func updateFrameTimeIfNecessary() {
        if currentFrameTime <= 0 {
            currentFrameTime = dom.getCurrentTime()
        }
    }

    private func scheduleFrameIfNecessary() {
        if !isAnimationFramePending && needsFrame {
            isAnimationFramePending = true
            dom.requestAnimationFrame { [self] _ in
                isAnimationFramePending = false
                flushCommitPlan()
                if !runningAnimations.isEmpty {
                    dom.runNext {
                        self.tickAnimations()
                    }
                }
            }
        }
    }

    private func flushCommitPlan() {
        var context = _CommitContext(dom: dom, currentFrameTime: currentFrameTime)
        currentFrameTime = 0

        for node in nodes {
            node.run(&context)
        }
        nodes.removeAll(keepingCapacity: true)

        for placement in placements.reversed() {
            placement.run(&context)
        }

        placements.removeAll(keepingCapacity: true)
        context.drain()
    }

    private func tickAnimations() {
        updateFrameTimeIfNecessary()

        var removedAnimations: [Int] = []

        for index in runningAnimations.indices {
            if !progressAnimation(runningAnimations[index]) {
                removedAnimations.append(index)
            }
        }

        for index in removedAnimations.reversed() {
            runningAnimations.remove(at: index)
        }

        scheduleFrameIfNecessary()
    }

    private func progressAnimation(_ animation: AnyAnimatable) -> Bool {
        var context = _RenderContext(
            scheduler: self,
            currentTime: currentFrameTime,
            transaction: nil
        )

        let isStillRunning = animation.progressAnimation(&context)

        context.drain()
        return isStillRunning
    }
}
