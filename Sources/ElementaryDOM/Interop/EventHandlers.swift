import JavaScriptKit

public protocol DOMEvent {
    init?(_: JSObject)
}

extension DOMEvent {
    init?(anyObject: AnyObject) {
        guard let rawEvent = anyObject as? JSObject else {
            return nil
        }

        self.init(rawEvent)
    }
}

extension DOMEvent {
    static func makeHandler(_ handler: @escaping (Self) -> Void) -> (AnyObject) -> Void {
        { event in
            guard let event = Self(anyObject: event) else {
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

public extension View {
    func onKeyDown(_ handler: @escaping (consuming KeyboardEvent) -> Void) -> _EventHandlingView<Self> {
        on("keydown", handler: KeyboardEvent.makeHandler(handler))
    }

    func onClick(_ handler: @escaping (consuming MouseEvent) -> Void) -> _EventHandlingView<Self> {
        on("click", handler: MouseEvent.makeHandler(handler))
    }
}
