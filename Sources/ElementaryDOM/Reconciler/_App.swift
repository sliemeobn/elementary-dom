// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: DOM.Interactor> {
    private var root: AnyParentElememnt?
    private var scheduler: Scheduler

    // TODO: rethink this whole API - maybe once usage of async is clearer
    // there should probably be a way to "unmount" the app
    init(dom: DOMInteractor) {
        self.scheduler = Scheduler(dom: dom)
        self.root = nil
    }

    // generic initializers must be convenience on final classes for embedded
    // https://github.com/swiftlang/swift/issues/78150
    convenience init<RootView: View>(dom: DOMInteractor, root rootView: consuming RootView) {
        self.init(dom: dom)

        // TODO: defer running to a "async run" function that hosts the run loop?
        // wait until async stuff is solid for embedded wasm case
        scheduler.scheduleFunction(
            .init(
                identifier: ObjectIdentifier(self),
                depthInTree: 0,
                runUpdate: { [self, rootView] context in
                    self.root =
                        _ElementNode(
                            root: dom.root,
                            context: &context,
                            makeChild: { [rootView] context in
                                RootView._makeNode(
                                    rootView,
                                    context: _ViewContext(),
                                    reconciler: &context
                                )
                            }
                        )
                        .asParentRef
                }
            )
        )
    }
}

// TODO: this ain't such a great shape...
final class Scheduler {
    private var dom: any DOM.Interactor
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()
    private var commitPlan: CommitPlan = .init()
    private var isAnimationFramePending: Bool = false

    private var ambientRenderContext: _RenderContext?

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    func scheduleFunction(_ function: AnyFunctionNode) {
        // NOTE: this is a bit of a hack to scheduel function in the same reconciler run if environment values change
        // we currently uses the same Reactivity tracking for environment changes, but they always happen during reconciliation
        if ambientRenderContext != nil {
            ambientRenderContext!.addFunction(function)
            return
        } else {
            if pendingFunctionsQueue.isEmpty {
                dom.queueMicrotask { [self] in
                    self.reconcile()
                }
            }

            pendingFunctionsQueue.registerFunctionForUpdate(function)
        }
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
