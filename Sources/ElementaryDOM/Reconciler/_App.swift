// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: DOM.Interactor> {
    private var root: AnyParentElememnt!
    private var scheduler: Scheduler

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
        var reconciler = _RenderContext(scheduler: scheduler)

        self.root =
            _ElementNode(
                root: dom.root,
                context: &reconciler,
                makeChild: { [rootView] context in
                    RootView._makeNode(
                        rootView,
                        context: _ViewContext(),
                        reconciler: &context
                    )
                }
            )
            .asParentRef

        scheduler.commit(reconciler.drain())
    }
}

final class Scheduler {
    private var dom: any DOM.Interactor
    private var pendingFunctionsQueue: PendingFunctionQueue = .init()

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    func scheduleFunction(_ function: AnyFunctionNode) {
        if pendingFunctionsQueue.isEmpty {
            //TODO: use next microtask instead of requestAnimationFrame
            dom.requestAnimationFrame { [self] _ in
                self.reconcile()
            }
        }

        pendingFunctionsQueue.registerFunctionForUpdate(function)
    }

    func reconcile() {
        var functions = PendingFunctionQueue()
        swap(&pendingFunctionsQueue, &functions)

        let plan = _RenderContext(
            scheduler: self,
            pendingFunctions: consume functions,
        ).drain()

        commit(consume plan)
    }

    // TODO: think about scheduling, rafs, multiple reconciler runs on the same commit plan, ...
    func commit(_ plan: consuming CommitPlan) {
        plan.flush(dom: &dom)
    }
}
