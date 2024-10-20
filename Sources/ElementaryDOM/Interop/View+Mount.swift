import JavaScriptKit

public extension View {
    // TODO: maybe return some kind of handle to ... unmount?
    consuming func mount(in domNode: JSObject) {
        let dom = JSKitDOMInteractor(root: domNode)
        _ = Reconciler(dom: dom, root: Self._renderView(self, context: .empty))
        // _ = Reconciler<DummyDOMInteractor>(dom: DummyDOMInteractor(), root: Self._renderView(self, context: .empty))
    }
}
