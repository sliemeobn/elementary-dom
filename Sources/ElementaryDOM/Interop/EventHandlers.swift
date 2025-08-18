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

extension DOMEvent {
    static func makeHandler(_ handler: @escaping (Self) -> Void) -> (DOM.Event) -> Void {
        { event in
            guard let event = Self(raw: event) else {
                assertionFailure("Bad event type")
                return
            }

            handler(event)
        }
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

public extension View {
    func onKeyDown(_ handler: @escaping (consuming KeyboardEvent) -> Void) -> _EventHandlingView<Self> {
        on("keydown", handler: KeyboardEvent.makeHandler(handler))
    }

    func onClick(_ handler: @escaping (consuming MouseEvent) -> Void) -> _EventHandlingView<Self> {
        on("click", handler: MouseEvent.makeHandler(handler))
    }

    func onInput(_ handler: @escaping (consuming InputEvent) -> Void) -> _EventHandlingView<Self> {
        on("input", handler: InputEvent.makeHandler(handler))
    }
}
