// TODO: rethink this whole API - maybe once usage of async is clearer
// TODO: there should probably be a way to "unmount" the app
// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
// TODO: find a good name for this
final class ApplicationRuntime<DOMInteractor: DOM.Interactor> {
    private var rootNode: _ElementNode?
    private var scheduler: Scheduler

    init(dom: DOMInteractor) {
        self.scheduler = Scheduler(dom: dom)
        self.rootNode = nil
    }

    // generic initializers must be convenience on final classes for embedded
    // https://github.com/swiftlang/swift/issues/78150
    convenience init<RootView: View>(dom: DOMInteractor, domRoot: DOM.Node, appView rootView: consuming RootView) {
        self.init(dom: dom)

        var rootTransaction = Transaction()
        rootTransaction.disablesAnimation = true

        // TODO: defer running to a "async run" function that hosts the run loop?
        // wait until async stuff is solid for embedded wasm case
        withTransaction(rootTransaction) { [rootView, domRoot] in
            scheduler.scheduleFunction(
                .init(
                    identifier: ObjectIdentifier(self),
                    depthInTree: 0,
                    runUpdate: { [self, rootView] context in
                        self.rootNode =
                            _ElementNode(
                                root: domRoot,
                                viewContext: _ViewContext(),
                                context: &context,
                                makeChild: { [rootView] viewContext, context in
                                    AnyReconcilable(
                                        RootView._makeNode(
                                            rootView,
                                            context: viewContext,
                                            tx: &context
                                        )
                                    )
                                }
                            )
                    }
                )
            )
        }
    }
}
