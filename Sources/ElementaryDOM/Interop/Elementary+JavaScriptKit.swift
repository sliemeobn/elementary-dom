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
        document.createTextNode(text).object!
    }

    func createElement(_ element: String) -> Node {
        document.createElement(element).object!
    }

    func patchElementAttributes(_ node: Node, with attributes: _AttributeStorage, replacing: _AttributeStorage) {
        // fast pass
        guard attributes != .none || replacing != .none else { return }

        var previous = replacing.flattened().reversed()
        for attribute in attributes.flattened() {
            let previousIndex = previous.firstIndex { $0.name == attribute.name }
            if let previousValue = previousIndex {
                let oldValue = previous.remove(at: previousValue)
                if oldValue.value != attribute.value {
                    print("updating attribute \(attribute.name) from \(oldValue.value) to \(attribute.value)")
                    _ = node.setAttribute!(attribute.name, attribute.value)
                }
            } else {
                print("setting attribute \(attribute.name) to \(attribute.value)")
                _ = node.setAttribute!(attribute.name, attribute.value)
            }
        }

        for attribute in previous {
            print("removing attribute \(attribute.name)")
            _ = node.removeAttribute!(attribute.name)
        }
    }

    func patchEventListeners(_ node: Node, with listers: _DomEventListenerStorage, replacing: _DomEventListenerStorage, sink: @autoclosure () -> EventSink) {
        guard !(listers.listeners.isEmpty && replacing.listeners.isEmpty) else { return }

        let new = listers.listeners.map(\.event)
        let old = replacing.listeners.map(\.event)
        let diff = new.difference(from: old)

        for change in diff {
            switch change {
            case let .insert(offset: _, element: event, associatedWith: _):
                print("adding listener \(event)")
                _ = node.addEventListener!(event, sink())
            case let .remove(offset: _, element: event, associatedWith: _):
                print("removing listener \(event)")
                _ = node.removeEventListener!(event, sink())
            }
        }
    }

    func patchText(_ node: Node, with text: String, replacing: String) {
        print("patching text \(replacing) -> \(text)")
        guard text != replacing else { return }
        _ = node.textContent = .string(text)
    }

    func replaceChildren(_ children: [Node], in parent: Node) {
        print("setting \(children.count) children in \(parent)")
        let function = parent.replaceChildren.function!
        function.callAsFunction(this: parent, arguments: children)
    }
}
