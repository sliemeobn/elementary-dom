import Elementary

protocol DOMInteracting {
    associatedtype Node
    associatedtype Event: AnyObject
    associatedtype EventSink

    var root: Node { get }

    func makeEventSink(_ handler: @escaping (String, Event) -> Void) -> EventSink

    func createText(_ text: String) -> Node
    func createElement(_ element: String) -> Node
    func patchElementAttributes(_ node: Node, with attributes: _AttributeStorage, replacing: _AttributeStorage)
    func patchEventListeners(
        _ node: Node,
        with listers: _DomEventListenerStorage,
        replacing: _DomEventListenerStorage,
        sink: @autoclosure () -> EventSink
    )
    func patchText(_ node: Node, with text: String, replacing: String)
    func replaceChildren(_ children: [Node], in parent: Node)

    func requestAnimationFrame(_ callback: @escaping (Double) -> Void)
}
