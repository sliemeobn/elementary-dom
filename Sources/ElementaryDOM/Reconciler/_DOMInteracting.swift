import Elementary

// Type-erased node reference
public enum DOM {
    public struct Node {
        let ref: AnyObject
    }

    public struct Event {
        let ref: AnyObject
    }

    public struct EventSink {
        let ref: AnyObject
    }

    // TODO: remove anyobject and make reconcier runs generic over this
    public protocol Interactor: AnyObject {
        var root: Node { get }

        func makeEventSink(_ handler: @escaping (String, Event) -> Void) -> EventSink

        func createText(_ text: String) -> Node
        func createElement(_ element: String) -> Node
        // Low-level DOM-like attribute APIs
        func setAttribute(_ node: Node, name: String, value: String?)
        func removeAttribute(_ node: Node, name: String)

        // Low-level DOM-like event listener APIs
        func addEventListener(_ node: Node, event: String, sink: EventSink)
        func removeEventListener(_ node: Node, event: String, sink: EventSink)
        func patchText(_ node: Node, with text: String)
        func replaceChildren(_ children: [Node], in parent: Node)
        // New explicit child list operations
        func insertChild(_ child: Node, before sibling: Node?, in parent: Node)
        func removeChild(_ child: Node, from parent: Node)

        func requestAnimationFrame(_ callback: @escaping (Double) -> Void)
    }
}

extension DOM.Interactor {
    func patchElementAttributes(
        _ node: DOM.Node,
        with attributes: _AttributeStorage,
        replacing: _AttributeStorage
    ) {
        // fast pass
        guard attributes != .none || replacing != .none else { return }

        var previous = replacing.flattened().reversed()
        for attribute in attributes.flattened() {
            let previousIndex = previous.firstIndex { $0.name.utf8Equals(attribute.name) }
            if let previousValue = previousIndex {
                let oldValue = previous.remove(at: previousValue)
                if !oldValue.value.utf8Equals(attribute.value) {
                    logTrace(
                        "updating attribute \(attribute.name) from \(oldValue.value ?? "") to \(attribute.value ?? "")"
                    )
                    setAttribute(node, name: attribute.name, value: attribute.value)
                }
            } else {
                logTrace("setting attribute \(attribute.name) to \(attribute.value ?? "")")
                setAttribute(node, name: attribute.name, value: attribute.value)
            }
        }

        for attribute in previous {
            logTrace("removing attribute \(attribute.name)")
            removeAttribute(node, name: attribute.name)
        }
    }

    func patchEventListeners(
        _ node: DOM.Node,
        with listers: _DomEventListenerStorage,
        replacing: _DomEventListenerStorage,
        sink: DOM.EventSink
    ) {
        guard !(listers.listeners.isEmpty && replacing.listeners.isEmpty) else { return }

        var previous = replacing.listeners.map { $0.event }

        for event in listers.listeners.map({ $0.event }) {
            let previousIndex = previous.firstIndex { $0.utf8Equals(event) }
            if let previousIndex {
                previous.remove(at: previousIndex)
            } else {
                logTrace("adding listener \(event)")
                addEventListener(node, event: event, sink: sink)
            }
        }

        for event in previous {
            logTrace("removing listener \(event)")
            removeEventListener(node, event: event, sink: sink)
        }
    }
}
