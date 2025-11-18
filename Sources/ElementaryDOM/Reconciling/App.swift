// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: DOM.Interactor> {
    private var root: _ElementNode?
    private var scheduler: Scheduler

    var rootTransaction: Transaction {
        var tx = Transaction()
        tx.disablesAnimation = true
        return tx
    }

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
        withTransaction(rootTransaction) { [rootView] in
            scheduler.scheduleFunction(
                .init(
                    identifier: ObjectIdentifier(self),
                    depthInTree: 0,
                    runUpdate: { [self, rootView] context in
                        self.root =
                            _ElementNode(
                                root: dom.root,
                                viewContext: _ViewContext(),
                                context: &context,
                                makeChild: { [rootView] viewContext, context in
                                    AnyReconcilable(
                                        RootView._makeNode(
                                            rootView,
                                            context: viewContext,
                                            reconciler: &context
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
