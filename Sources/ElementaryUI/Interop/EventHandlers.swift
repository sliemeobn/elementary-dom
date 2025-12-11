import JavaScriptKit

public protocol DOMEvent {
    init?(_: JSObject)
}

extension DOMEvent {
    init?(raw: DOM.Event) {
        guard let rawEvent = raw.ref as? JSObject else {
            return nil
        }

        self.init(rawEvent)
    }
}

public struct KeyboardEvent: DOMEvent {
    var rawEvent: JSObject

    public init?(_ rawEvent: JSObject) {
        // TODO: maybe check some stuff..
        self.rawEvent = rawEvent
    }

    public var key: String {
        rawEvent.key.string!
    }
}

public struct MouseEvent: DOMEvent {
    var rawEvent: JSObject

    public init?(_ rawEvent: JSObject) {
        // TODO: maybe check some stuff..
        self.rawEvent = rawEvent
    }

    public var altKey: Bool {
        rawEvent.altKey.boolean!
    }

    public var button: Int {
        Int(rawEvent.button.number!)
    }

    public var buttons: Int {
        Int(rawEvent.buttons.number!)
    }

    public var clientX: Double {
        rawEvent.clientX.number!
    }

    public var clientY: Double {
        rawEvent.clientY.number!
    }

    public var ctrlKey: Bool {
        rawEvent.ctrlKey.boolean!
    }

    public var metaKey: Bool {
        rawEvent.metaKey.boolean!
    }

    public var movementX: Double {
        rawEvent.movementX.number!
    }

    public var movementY: Double {
        rawEvent.movementY.number!
    }

    public var offsetX: Double {
        rawEvent.offsetX.number!
    }

    public var offsetY: Double {
        rawEvent.offsetY.number!
    }

    public var pageX: Double {
        rawEvent.pageX.number!
    }

    public var pageY: Double {
        rawEvent.pageY.number!
    }

    public var screenX: Double {
        rawEvent.screenX.number!
    }

    public var screenY: Double {
        rawEvent.screenY.number!
    }

    public var shiftKey: Bool {
        rawEvent.shiftKey.boolean!
    }
}

public struct InputEvent: DOMEvent {
    var rawEvent: JSObject

    public init?(_ rawEvent: JSObject) {
        self.rawEvent = rawEvent
    }

    public var data: String? {
        rawEvent.data.string
    }

    public var targetValue: String? {
        rawEvent.target.value.string
    }
}
