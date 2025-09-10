import Elementary
import JavaScriptKit

extension DOM.Node {
    init(_ node: JSObject) { self.init(ref: node) }
    var jsObject: JSObject { ref as! JSObject }
}

extension DOM.Event {
    init(_ event: JSObject) { self.init(ref: event) }
    var jsObject: JSObject { ref as! JSObject }
}

extension DOM.EventSink {
    init(_ sink: JSClosure) { self.init(ref: sink) }
    var jsClosure: JSClosure { ref as! JSClosure }
}

final class JSKitDOMInteractor: DOM.Interactor {
    private let document = JSObject.global.document
    private let setTimeout = JSObject.global.setTimeout.function!
    private let requestAnimationFrame = JSObject.global.requestAnimationFrame.function!
    private let queueMicrotask = JSObject.global.queueMicrotask.function!

    let root: DOM.Node

    init(root: JSObject) {
        self.root = .init(root)

        #if hasFeature(Embedded)
        if __omg_this_was_annoying_I_am_false {
            // NOTE: this is just to force inclusion of some types that would otherwise crash the 6.2 compiler
            _ = JSClosure { _ in .undefined }
        }
        #endif
    }

    func makeEventSink(_ handler: @escaping (String, DOM.Event) -> Void) -> DOM.EventSink {
        .init(
            JSClosure { arguments in
                guard arguments.count >= 1 else { return .undefined }

                guard let event = arguments[0].object, let type = event.type.string else {
                    return .undefined
                }

                handler(type, .init(event))
                return .undefined
            }
        )
    }

    func createText(_ text: String) -> DOM.Node {
        .init(document.createTextNode(text).object!)
    }

    func createElement(_ element: String) -> DOM.Node {
        .init(document.createElement(element).object!)
    }

    // Low-level DOM-like operations used by protocol extensions
    func setAttribute(_ node: DOM.Node, name: String, value: String?) {
        _ = node.jsObject.setAttribute!(name.jsValue, value.jsValue)
    }

    func removeAttribute(_ node: DOM.Node, name: String) {
        _ = node.jsObject.removeAttribute!(name)
    }

    func addEventListener(_ node: DOM.Node, event: String, sink: DOM.EventSink) {
        _ = node.jsObject.addEventListener!(event.jsValue, sink.jsClosure.jsValue)
    }

    func removeEventListener(_ node: DOM.Node, event: String, sink: DOM.EventSink) {
        _ = node.jsObject.removeEventListener!(event.jsValue, sink.jsClosure.jsValue)
    }

    func patchText(_ node: DOM.Node, with text: String) {
        _ = node.jsObject.textContent = text.jsValue
    }

    func replaceChildren(_ children: [DOM.Node], in parent: DOM.Node) {
        logTrace("setting \(children.count) children in \(parent)")
        let function = parent.jsObject.replaceChildren.function!
        function.callAsFunction(
            this: parent.jsObject,
            arguments: children.map { $0.jsObject.jsValue }
        )
    }

    func insertChild(_ child: DOM.Node, before sibling: DOM.Node?, in parent: DOM.Node) {
        if let s = sibling {
            _ = parent.jsObject.insertBefore!(child.jsObject.jsValue, s.jsObject.jsValue)
        } else {
            _ = parent.jsObject.appendChild!(child.jsObject.jsValue)
        }
    }

    func removeChild(_ child: DOM.Node, from parent: DOM.Node) {
        _ = parent.jsObject.removeChild!(child.jsObject.jsValue)
    }

    func requestAnimationFrame(_ callback: @escaping (Double) -> Void) {
        // TODO: optimize this
        requestAnimationFrame(
            JSOneshotClosure { args in
                callback(args[0].number!)
                return .undefined
            }.jsValue
        )
    }

    func queueMicrotask(_ callback: @escaping () -> Void) {
        queueMicrotask(
            JSOneshotClosure { args in
                callback()
                return .undefined
            }.jsValue
        )
    }

    func setTimeout(_ callback: @escaping () -> Void, _ timeout: Double) {
        setTimeout(
            JSOneshotClosure { args in
                callback()
                return .undefined
            }.jsValue,
            timeout
        )
    }
}
