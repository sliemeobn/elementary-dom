// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: DOM.Interactor> {
    typealias Reconciler = _ReconcilerBatch

    private var dom: DOMInteractor
    private var root: (any ParentElement)!

    private var nextUpdateRun: Reconciler.PendingFunctionQueue = .init()

    init<RootView: View>(dom: DOMInteractor, root rootView: consuming RootView) {
        self.dom = dom

        self.root = Element(
            root: dom.root,
            makeReconciler: { node in
                Reconciler(
                    dom: dom,
                    parentElement: node,
                    pendingFunctions: .init(),
                    reportObservedChange: self.scheduleFunction
                )
            },
            makeChild: { [rootView] reconciler in
                RootView._makeNode(
                    rootView,
                    context: _ViewRenderingContext(),
                    reconciler: &reconciler
                )
            }
        )
    }

    func scheduleFunction(_ function: any FunctionNode) {
        if nextUpdateRun.isEmpty {
            //TODO: use next microtask instead of requestAnimationFrame
            dom.requestAnimationFrame { [self] _ in
                var updateRun = Reconciler(
                    dom: dom,
                    parentElement: root,
                    pendingFunctions: self.takeNextUpdateRun(),
                    reportObservedChange: scheduleFunction
                )

                updateRun.run()
            }
        }

        nextUpdateRun.registerFunctionForUpdate(function)
    }

    private func takeNextUpdateRun() -> Reconciler.PendingFunctionQueue {
        var nextUpdateRun = Reconciler.PendingFunctionQueue()
        swap(&nextUpdateRun, &self.nextUpdateRun)
        return nextUpdateRun
    }
}
