// TODO: find a better name for this
struct AnyFunctionNode {
    let identifier: ObjectIdentifier
    let depthInTree: Int
    let runUpdate: (inout _RenderContext) -> Void
}

enum AnimationProgressResult {
    case stillRunning
    case completed
}

struct AnyAnimatable {
    let progressAnimation: (inout _RenderContext) -> AnimationProgressResult
}

struct CommitAction {
    // TODO: is there a way to make this allocation-free?
    let run: (inout _CommitContext) -> Void
}

// TODO: this ain't such a great shape...
final class Scheduler {
    private var dom: any DOM.Interactor
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()
    private var runningAnimations: [AnyAnimatable] = []

    private var nodeActions: [CommitAction] = []
    private var placementActions: [CommitAction] = []

    private var isAnimationFramePending: Bool = false

    private var currentTransaction: Transaction?
    private var currentFrameTime: Double = 0

    // TODO: this is a bit hacky, ideally we can use explicit depencies on Environment
    private var ambientRenderContext: _RenderContext?

    private var needsFrame: Bool { !nodeActions.isEmpty || !placementActions.isEmpty || !runningAnimations.isEmpty }

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

    // TODO: maybe add a second call for scheduleing a one-short "nextFrame" callback
    func registerAnimation(_ node: AnyAnimatable) {
        runningAnimations.append(node)
        scheduleFrameIfNecessary()
    }

    func addNodeAction(_ action: CommitAction) {
        nodeActions.append(action)
    }

    func addPlacementAction(_ action: CommitAction) {
        placementActions.append(action)
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
                currentTransaction = nil
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

        for node in nodeActions {
            node.run(&context)
        }
        nodeActions.removeAll(keepingCapacity: true)

        for placement in placementActions.reversed() {
            placement.run(&context)
        }

        placementActions.removeAll(keepingCapacity: true)
        context.drain()
    }

    private func tickAnimations() {
        updateFrameTimeIfNecessary()

        var removedAnimations: [Int] = []

        for index in runningAnimations.indices {
            switch progressAnimation(runningAnimations[index]) {
            case .completed:
                removedAnimations.append(index)
            case .stillRunning:
                break
            }
        }

        for index in removedAnimations.reversed() {
            runningAnimations.remove(at: index)
        }

        scheduleFrameIfNecessary()
    }

    private func progressAnimation(_ animation: AnyAnimatable) -> AnimationProgressResult {
        var context = _RenderContext(
            scheduler: self,
            currentTime: currentFrameTime,
            transaction: nil
        )

        let result = animation.progressAnimation(&context)

        context.drain()
        return result
    }
}
