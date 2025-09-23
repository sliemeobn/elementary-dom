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

extension DOM.PropertyValue {
    var jsValue: JSValue {
        switch self {
        case let .string(value):
            return value.jsValue
        case let .number(value):
            return value.jsValue
        case let .boolean(value):
            return value.jsValue
        case let .stringArray(value):
            return value.jsValue
        case .null:
            return .null
        case .undefined:
            return .undefined
        }
    }

    init?(_ jsValue: JSValue) {
        switch jsValue {
        case let .string(value):
            self = .string(value.description)
        case let .number(value):
            self = .number(value)
        case let .boolean(value):
            self = .boolean(value)
        case let .object(object):
            guard let array = JSArray(object) else { return nil }
            self = .stringArray(array.compactMap { $0.string })
        case .null:
            self = .null
        case .undefined:
            self = .undefined
        default:
            return nil
        }
    }
}

final class JSKitDOMInteractor: DOM.Interactor {
    private let jsDocument = JSObject.global.document
    private let jsSetTimeout = JSObject.global.setTimeout.function!
    private let jsRequestAnimationFrame = JSObject.global.requestAnimationFrame.function!
    private let jsQueueMicrotask = JSObject.global.queueMicrotask.function!
    private let jsPerformance = JSObject.global.performance.object!

    let root: DOM.Node

    init(root: JSObject) {
        self.root = .init(root)

        #if hasFeature(Embedded)
        if __omg_this_was_annoying_I_am_false {
            // NOTE: this is just to force inclusion of some types that would otherwise crash the 6.2 compiler
            _ = JSClosure { _ in .undefined }
            _ = JSFunction()
            _ = JSFunction?(nil)
            _ = JSArray.constructor?.jsValue
            // _ = JSClosure?(nil)
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

    func makePropertyAccessor(_ node: DOM.Node, name: String) -> DOM.PropertyAccessor {
        let propertyName = JSString(name)
        let object = node.jsObject
        return .init(
            get: { .init(getJSValue(this: object, name: propertyName)) },
            set: { setJSValue(this: object, name: propertyName, value: $0.jsValue) }
        )
    }

    func makeStyleAccessor(_ node: DOM.Node, cssName: String) -> DOM.StyleAccessor {
        let propertyName = JSString(cssName)
        let style = node.jsObject.style

        return .init(
            get: { style.getPropertyValue(propertyName.jsValue).string ?? "" },
            set: { _ = style.setProperty(propertyName.jsValue, $0.jsValue) }
        )
    }

    func setStyleProperty(_ node: DOM.Node, name: String, value: String) {
        let style = node.jsObject.style
        _ = style.setProperty(JSString(name).jsValue, JSString(value).jsValue)
    }

    func removeStyleProperty(_ node: DOM.Node, name: String) {
        let style = node.jsObject.style
        _ = style.removeProperty(JSString(name).jsValue)
    }

    func createText(_ text: String) -> DOM.Node {
        .init(jsDocument.createTextNode(text).object!)
    }

    func createElement(_ element: String) -> DOM.Node {
        .init(jsDocument.createElement(element).object!)
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
        node.jsObject.textContent = text.jsValue
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
        jsRequestAnimationFrame(
            JSOneshotClosure { args in
                callback(args[0].number!)
                return .undefined
            }.jsValue
        )
    }

    func queueMicrotask(_ callback: @escaping () -> Void) {
        jsQueueMicrotask(
            JSOneshotClosure { args in
                callback()
                return .undefined
            }.jsValue
        )
    }

    func setTimeout(_ callback: @escaping () -> Void, _ timeout: Double) {
        jsSetTimeout(
            JSOneshotClosure { args in
                callback()
                return .undefined
            }.jsValue,
            timeout
        )
    }

    func getCurrentTime() -> Double {
        jsPerformance.now!().number! / 1000
    }
}
