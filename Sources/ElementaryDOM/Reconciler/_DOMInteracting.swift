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

    public struct StyleAccessor {
        let _get: () -> String
        let _set: (String) -> Void

        init(
            get: @escaping () -> String,
            set: @escaping (String) -> Void
        ) {
            self._get = get
            self._set = set
        }

        func get() -> String {
            _get()
        }

        func set(_ value: String) {
            _set(value)
        }
    }

    // TODO: remove anyobject and make reconcier runs generic over this
    public protocol Interactor: AnyObject {
        var root: Node { get }

        func makeEventSink(_ handler: @escaping (String, Event) -> Void) -> EventSink

        func makePropertyAccessor(_ node: Node, name: String) -> PropertyAccessor
        func makeStyleAccessor(_ node: Node, cssName: String) -> StyleAccessor

        // Fine-grained style property operations
        func setStyleProperty(_ node: Node, name: String, value: String)
        func removeStyleProperty(_ node: Node, name: String)

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
            if let previousIndex = previous.firstIndex(where: { $0.name.utf8Equals(attribute.name) }) {
                let oldValue = previous.remove(at: previousIndex)
                if !oldValue.value.utf8Equals(attribute.value) {
                    if attribute.name.utf8Equals("style") {
                        let oldMap = _parseInlineStyle(oldValue.value)
                        let newMap = _parseInlineStyle(attribute.value)
                        _applyInlineStyles(node, old: oldMap, new: newMap)
                    } else {

                        logTrace(
                            "updating attribute \(attribute.name) from \(oldValue.value ?? "") to \(attribute.value ?? "")"
                        )
                        setAttribute(node, name: attribute.name, value: attribute.value)
                    }
                }
            } else {
                if attribute.name.utf8Equals("style") {
                    let newMap = _parseInlineStyle(attribute.value)
                    _applyInlineStyles(node, old: [:], new: newMap)
                } else {
                    logTrace("setting attribute \(attribute.name) to \(attribute.value ?? "")")
                    setAttribute(node, name: attribute.name, value: attribute.value)
                }
            }
        }

        for attribute in previous {
            if attribute.name.utf8Equals("style") {
                let oldMap = _parseInlineStyle(attribute.value)
                _applyInlineStyles(node, old: oldMap, new: [:])
            } else {
                logTrace("removing attribute \(attribute.name)")
                removeAttribute(node, name: attribute.name)
            }
        }
    }
}

// NOTE: AI slop below, don't judge me
private func _isASCIISpace(_ byte: UInt8) -> Bool {
    // space, tab, LF, CR, FF
    byte == 32 || byte == 9 || byte == 10 || byte == 13 || byte == 12
}

func _parseInlineStyle(_ value: String?) -> [PropertyID: String] {
    guard let value, !value.isEmpty else { return [:] }
    var result: [PropertyID: String] = [:]

    let bytes = value.utf8
    var i = bytes.startIndex
    let end = bytes.endIndex

    let colon: UInt8 = 58  // ':'
    let semicolon: UInt8 = 59  // ';'

    var nameBuf: [UInt8] = []
    var valueBuf: [UInt8] = []

    while i < end {
        // skip leading whitespace
        while i < end, _isASCIISpace(bytes[i]) { i = bytes.index(after: i) }
        if i >= end { break }

        // read name
        nameBuf.removeAll(keepingCapacity: true)
        var nameLen = 0
        while i < end {
            let b = bytes[i]
            if b == colon || b == semicolon { break }
            nameBuf.append(b)
            if !_isASCIISpace(b) { nameLen = nameBuf.count }
            i = bytes.index(after: i)
        }
        if nameLen < nameBuf.count { nameBuf.removeLast(nameBuf.count - nameLen) }

        // check for value
        var hasValue = false
        if i < end, bytes[i] == colon {
            hasValue = true
            i = bytes.index(after: i)  // skip ':'
        } else {
            // skip until semicolon or end
            while i < end, bytes[i] != semicolon { i = bytes.index(after: i) }
        }

        valueBuf.removeAll(keepingCapacity: true)
        var valueLen = 0
        if hasValue {
            // skip whitespace after ':'
            while i < end, _isASCIISpace(bytes[i]) { i = bytes.index(after: i) }
            while i < end, bytes[i] != semicolon {
                let b = bytes[i]
                valueBuf.append(b)
                if !_isASCIISpace(b) { valueLen = valueBuf.count }
                i = bytes.index(after: i)
            }
            if valueLen < valueBuf.count { valueBuf.removeLast(valueBuf.count - valueLen) }
        }

        if !nameBuf.isEmpty {
            let nameString = String(decoding: nameBuf, as: UTF8.self)
            let valueString = String(decoding: valueBuf, as: UTF8.self)
            if !nameString.isEmpty {
                result[PropertyID(nameString)] = valueString
            }
        }

        // skip semicolon if present
        if i < end, bytes[i] == semicolon {
            i = bytes.index(after: i)
        }
    }

    return result
}

private extension DOM.Interactor {
    func _applyInlineStyles(_ node: DOM.Node, old: [PropertyID: String], new: [PropertyID: String]) {
        // Set or update
        for (k, v) in new {
            if let ov = old[k] {
                if !ov.utf8Equals(v) {
                    setStyleProperty(node, name: k.description, value: v)
                }
            } else {
                setStyleProperty(node, name: k.description, value: v)
            }
        }
        // Removals
        for (k, _) in old {
            if new[k] == nil {
                removeStyleProperty(node, name: k.description)
            }
        }
    }
}
