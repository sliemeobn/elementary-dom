import Elementary
import JavaScriptKit

final class JSKitDOMInteractor: _DOMInteracting {
    typealias Node = JSObject
    typealias Event = JSObject
    typealias EventSink = JSValue

    let document = JSObject.global.document
    let root: Node

    init(root: Node) {
        self.root = root
    }

    func makeEventSink(_ handler: @escaping (String, Event) -> Void) -> EventSink {
        JSValue.object(
            JSClosure { arguments in
                guard arguments.count >= 1 else { return .undefined }

                guard let event = arguments[0].object, let type = event.type.string else {
                    return .undefined
                }

                handler(type, event)
                return .undefined
            }
        )
    }

    func createText(_ text: String) -> Node {
        document.createTextNode(text.jsValue).object!
    }

    func createElement(_ element: String) -> Node {
        document.createElement(element.jsValue).object!
    }

    // Low-level DOM-like operations used by protocol extensions
    func setAttribute(_ node: Node, name: String, value: String?) {
        _ = node.setAttribute!(name.jsValue, value.jsValue)
    }

    func removeAttribute(_ node: Node, name: String) {
        _ = node.removeAttribute!(name)
    }

    func addEventListener(_ node: Node, event: String, sink: EventSink) {
        _ = node.addEventListener!(event.jsValue, sink)
    }

    func removeEventListener(_ node: Node, event: String, sink: EventSink) {
        _ = node.removeEventListener!(event.jsValue, sink)
    }

    func patchText(_ node: Node, with text: String, replacing: String) {
        guard !text.utf8Equals(replacing) else { return }
        _ = node.textContent = text.jsValue
    }

    func replaceChildren(_ children: [Node], in parent: Node) {
        logTrace("setting \(children.count) children in \(parent)")
        let function = parent.replaceChildren.function!
        function.callAsFunction(
            this: parent,
            arguments: children.map { $0.jsValue }
        )
    }

    func insertChild(_ child: Node, before sibling: Node?, in parent: Node) {
        if let s = sibling {
            _ = parent.insertBefore!(child, s)
        } else {
            _ = parent.appendChild!(child)
        }
    }

    func removeChild(_ child: Node, from parent: Node) {
        _ = parent.removeChild!(child)
    }

    func requestAnimationFrame(_ callback: @escaping (Double) -> Void) {
        _ = JSObject.global.requestAnimationFrame!(
            JSClosure { args in
                callback(args[0].number!)
                return .undefined
            }.jsValue
        )
    }
}
