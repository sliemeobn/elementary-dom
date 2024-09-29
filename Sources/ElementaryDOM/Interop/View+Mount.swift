import JavaScriptKit

public extension View {
    // TODO: maybe return some kind of handle to ... unmount?
    @MainActor
    consuming func mount(in domNode: JSObject) {
        let dom = JSKitDOMInteractor(root: domNode)
        _ = Reconciler(dom: dom, root: self)
    }
}
