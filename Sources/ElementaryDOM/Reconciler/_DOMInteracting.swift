import Elementary
import JavaScriptKit

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

    public enum PropertyValue {
        case string(String)
        case number(Double)
        case boolean(Bool)
        case stringArray([String])
        case null
        case undefined
    }

    public struct PropertyAccessor {
        let _get: () -> PropertyValue?
        let _set: (PropertyValue) -> Void

        init(
            get: @escaping () -> PropertyValue?,
            set: @escaping (PropertyValue) -> Void
        ) {
            self._get = get
            self._set = set
        }

        func get() -> PropertyValue? {
            _get()
        }

        func set(_ value: PropertyValue) {
            _set(value)
        }
    }

    // TODO: remove anyobject and make reconcier runs generic over this
    public protocol Interactor: AnyObject {
        var root: Node { get }

        func makeEventSink(_ handler: @escaping (String, Event) -> Void) -> EventSink

        func makePropertyAccessor(_ node: Node, name: String) -> PropertyAccessor

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

        // TODO: these are more scheduling APIs, but they kind of fit here...
        func requestAnimationFrame(_ callback: @escaping (Double) -> Void)
        func queueMicrotask(_ callback: @escaping () -> Void)
        func setTimeout(_ callback: @escaping () -> Void, _ timeout: Double)
        func getCurrentTime() -> Double
    }
}

extension DOM.Interactor {
    func runNext(_ callback: @escaping () -> Void) {
        setTimeout(callback, 0)
    }

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
}
