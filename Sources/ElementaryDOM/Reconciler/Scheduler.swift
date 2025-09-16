// TODO: this ain't such a great shape...
final class Scheduler {
    private var dom: any DOM.Interactor
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()
    private var commitPlan: CommitPlan = .init()
    private var isAnimationFramePending: Bool = false
    private var currentTransaction: Transaction?

    // TODO: this is a bit hacky, ideally we can use explicit depencies on Environment
    private var ambientRenderContext: _RenderContext?

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
                self.reconcile()
            }
        } else if currentTransaction?._id != Transaction._current?._id {
            // in-line a reconcile run if the transaction has changed
            reconcile()
            currentTransaction = Transaction._current
        }

        pendingFunctionsQueue.registerFunctionForUpdate(function)
    }

    func withAmbientRenderContext(_ context: inout _RenderContext, _ block: () -> Void) {
        precondition(ambientRenderContext == nil, "ambient reconciliation already exists")
        ambientRenderContext = consume context
        block()
        context = ambientRenderContext.take()!
    }

    private func reconcile() {
        // TODO: this is awkward, refactor the reconciler API
        var functions = PendingFunctionQueue()
        var plan = CommitPlan()
        swap(&pendingFunctionsQueue, &functions)
        swap(&plan, &self.commitPlan)

        self.commitPlan = _RenderContext(
            scheduler: self,
            transaction: self.currentTransaction,
            commitPlan: consume plan,
            pendingFunctions: consume functions,
        ).drain()

        requestFramePaint()
    }

    private func requestFramePaint() {
        if !isAnimationFramePending {
            isAnimationFramePending = true
            dom.requestAnimationFrame { [self] _ in
                isAnimationFramePending = false
                flushCommitPlan()
            }
        }
    }

    private func flushCommitPlan() {
        var plan = CommitPlan()
        swap(&plan, &self.commitPlan)
        plan.flush(dom: &dom)
    }
}
