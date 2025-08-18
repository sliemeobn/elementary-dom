// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: DOM.Interactor> {
    typealias Reconciler = _ReconcilerBatch

    private var dom: DOMInteractor
    private var root: AnyLayoutContainer!

    private var nextUpdateRun: Reconciler.PendingFunctionQueue = .init()

    init(dom: DOMInteractor) {
        self.dom = dom
        self.root = nil
    }

    // generic initializers must be convenience on final classes for embedded
    // https://github.com/swiftlang/swift/issues/78150
    convenience init<RootView: View>(dom: DOMInteractor, root rootView: consuming RootView) {
        self.init(dom: dom)

        self.root =
            Element(
                root: dom.root,
                makeReconciler: { node in
                    Reconciler(
                        dom: dom,
                        parentElement: node.asLayoutContainer,
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
            .asLayoutContainer
    }

    func scheduleFunction(_ function: AnyFunctionNode) {
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
