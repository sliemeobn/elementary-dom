import Elementary

protocol DOMLayoutObserver: Unmountable {
    func willLayoutChildren(parent: DOM.Node, context: inout _RenderContext)
    func setLeaveStatus(_ node: DOM.Node, isLeaving: Bool, context: inout _RenderContext)
    func didLayoutChildren(parent: DOM.Node, entries: [ContainerLayoutPass.Entry], context: inout _CommitContext)
}

struct DOMLayoutObservers {
    private var storage: [any DOMLayoutObserver] = []

    mutating func add(_ observer: any DOMLayoutObserver) {
        storage.append(observer)
    }

    mutating func take() -> [any DOMLayoutObserver] {
        let observers = storage
        storage.removeAll(keepingCapacity: true)
        return observers
    }
}
