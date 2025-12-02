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
    let run: (inout _CommitContext) -> Void
}

final class Scheduler {
    private var dom: any DOM.Interactor

    // Phase 1: View function updates (reconciliation)
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()

    // Phase 2: After reconciliation callbacks (onChange)
    private var afterReconcileCallbacks: [() -> Void] = []

    // Phase 3: DOM operations (RAF)
    private var commitActions: [CommitAction] = []
    private var placementActions: [CommitAction] = []

    // Phase 4: Next tick callbacks (onAppear, onDisappear)
    private var onNextTickCallbacks: [() -> Void] = []

    // Continuous: Animations
    private var runningAnimations: [AnyAnimatable] = []

    // TODO: ideally this could be a completely decoupled extensions-style thing, but for now it's just here
    let flip: FLIPScheduler

    private var isAnimationFramePending: Bool = false
    private var currentTransaction: Transaction?
    private var currentFrameTime: Double = 0

    // TODO: this is a bit hacky, ideally we can use explicit dependencies on Environment
    private var ambientRenderContext: _RenderContext?

    private var needsFrame: Bool { !commitActions.isEmpty || !placementActions.isEmpty || !runningAnimations.isEmpty }

    init(dom: any DOM.Interactor) {
        self.dom = dom
        self.flip = FLIPScheduler(dom: dom)  // TODO: make this more pluggable
    }

    func scheduleFunction(_ function: AnyFunctionNode) {
        // NOTE: this is a bit of a hack to scheduel function in the same reconciler run if environment values change
        // we currently uses the same Reactivity tracking for environment changes, but they always happen during reconciliation
        guard ambientRenderContext == nil else {
            ambientRenderContext!.addFunction(function, transaction: ambientRenderContext!.transaction)
            return
        }

        if pendingFunctionsQueue.isEmpty {
            currentTransaction = Transaction._current

            dom.queueMicrotask { [self] in
                self.reconcileTransaction()

                // Flush afterReconcile callbacks (onChange)
                if !self.afterReconcileCallbacks.isEmpty {
                    let callbacks = self.afterReconcileCallbacks
                    self.afterReconcileCallbacks.removeAll(keepingCapacity: true)
                    for callback in callbacks {
                        callback()
                    }
                }
            }
        } else if currentTransaction?._id != Transaction._current?._id {
            // in-line a reconcile run if the transaction has changed
            reconcileTransaction()
            currentTransaction = Transaction._current
        }

        pendingFunctionsQueue.registerFunctionForUpdate(function, transaction: currentTransaction)
    }

    /// Register a continuous animation
    func registerAnimation(_ node: AnyAnimatable) {
        runningAnimations.append(node)
        scheduleFrameIfNecessary()
    }

    /// Schedule a callback to run after reconciliation completes (for onChange)
    func afterReconcile(_ callback: @escaping () -> Void) {
        afterReconcileCallbacks.append(callback)
    }

    /// Schedule a DOM operation for the commit phase (RAF)
    func addCommitAction(_ action: CommitAction) {
        commitActions.append(action)
        scheduleFrameIfNecessary()
    }

    /// Schedule a DOM placement for the commit phase (RAF, runs in reverse order)
    func addPlacementAction(_ action: CommitAction) {
        placementActions.append(action)
    }

    /// Schedule a callback for next tick after RAF (for onAppear, onDisappear)
    func onNextTick(_ callback: @escaping () -> Void) {
        onNextTickCallbacks.append(callback)
    }

    func withAmbientRenderContext(_ context: inout _RenderContext, _ block: () -> Void) {
        precondition(ambientRenderContext == nil, "ambient reconciliation already exists")
        ambientRenderContext = consume context
        block()
        context = ambientRenderContext.take()!
    }

    private func reconcileTransaction() {
        // Frame time is set to 0 on every paint, first reconcile after RAF establishes the time
        updateFrameTimeIfNecessary()

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
        var context = _CommitContext(
            dom: dom,
            scheduler: self,
            currentFrameTime: currentFrameTime
        )
        currentFrameTime = 0

        for action in commitActions {
            action.run(&context)
        }
        commitActions.removeAll(keepingCapacity: true)

        for placement in placementActions.reversed() {
            placement.run(&context)
        }
        placementActions.removeAll(keepingCapacity: true)

        // Phase 3: Process FLIP animations (commit, measure LAST, apply)
        flip.commitScheduledAnimations(context: &context)

        // Phase 5: Next tick callbacks (onAppear, onDisappear)
        if !onNextTickCallbacks.isEmpty {
            let callbacks = onNextTickCallbacks
            onNextTickCallbacks.removeAll(keepingCapacity: true)
            dom.runNext {
                for callback in callbacks {
                    callback()
                }
            }
        }
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
        var transaction = Transaction()
        transaction.disablesAnimation = true

        var context = _RenderContext(
            scheduler: self,
            currentTime: currentFrameTime,
            transaction: transaction
        )

        let result = animation.progressAnimation(&context)

        context.drain()
        return result
    }
}
