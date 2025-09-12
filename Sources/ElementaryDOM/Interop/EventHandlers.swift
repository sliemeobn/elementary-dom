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
