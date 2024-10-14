import Elementary
import JavaScriptKit

final class JSKitDOMInteractor: DOMInteracting {
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
            })
    }

    func createText(_ text: String) -> Node {
        document.createTextNode(text.jsValue).object!
    }

    func createElement(_ element: String) -> Node {
        document.createElement(element.jsValue).object!
    }

    func patchElementAttributes(_ node: Node, with attributes: _AttributeStorage, replacing: _AttributeStorage) {
        // fast pass
        guard attributes != .none || replacing != .none else { return }

        var previous = replacing.flattened().reversed()
        for attribute in attributes.flattened() {
            let previousIndex = previous.firstIndex { $0.name.utf8Equals(attribute.name) }
            if let previousValue = previousIndex {
                let oldValue = previous.remove(at: previousValue)
                if !oldValue.value.utf8Equals(attribute.value) {
                    print("updating attribute \(attribute.name) from \(oldValue.value ?? "") to \(attribute.value ?? "")")
                    _ = node.setAttribute!(attribute.name.jsValue, attribute.value.jsValue)
                }
            } else {
                print("setting attribute \(attribute.name) to \(attribute.value ?? "")")
                _ = node.setAttribute!(attribute.name.jsValue, attribute.value.jsValue)
            }
        }

        for attribute in previous {
            print("removing attribute \(attribute.name)")
            _ = node.removeAttribute!(attribute.name)
        }
    }

    func patchEventListeners(_ node: Node, with listers: _DomEventListenerStorage, replacing: _DomEventListenerStorage, sink: @autoclosure () -> EventSink) {
        guard !(listers.listeners.isEmpty && replacing.listeners.isEmpty) else { return }

        var previous = replacing.listeners.map { $0.event }

        for event in listers.listeners.map({ $0.event }) {
            let previousIndex = previous.firstIndex { $0.utf8Equals(event) }
            if let previousIndex {
                previous.remove(at: previousIndex)
            } else {
                print("adding listener \(event)")
                _ = node.addEventListener!(event.jsValue, sink().jsValue)
            }
        }

        for event in previous {
            print("removing listener \(event)")
            _ = node.removeEventListener!(event.jsValue, sink().jsValue)
        }
    }

    func patchText(_ node: Node, with text: String, replacing: String) {
        guard !text.utf8Equals(replacing) else { return }
        _ = node.textContent = text.jsValue
    }

    func replaceChildren(_ children: [Node], in parent: Node) {
        print("setting \(children.count) children in \(parent)")
        let function = parent.replaceChildren.function!
        function.callAsFunction(
            this: parent,
            arguments: children.map { $0.jsValue }
        )
    }

    func requestAnimationFrame(_ callback: @escaping (Double) -> Void) {
        _ = JSObject.global.requestAnimationFrame!(JSClosure { args in
            callback(args[0].number!)
            return .undefined
        }.jsValue)
    }
}
