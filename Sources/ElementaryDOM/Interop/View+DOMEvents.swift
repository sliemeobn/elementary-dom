import Elementary

public extension View {
    consuming func onEvent<Config: DOMEventHandlerConfig>(
        _ type: Config.Type,
        handler: @escaping (Config.Event) -> Void
    ) -> some View {
        DOMEffectView<EventModifier<Config>, Self>(value: handler, wrapped: self)
    }

    consuming func onClick(_ handler: @escaping (MouseEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.Click.self, handler: handler)
    }

    consuming func onClick(_ handler: @escaping () -> Void) -> some View {
        onClick { _ in handler() }
    }

    consuming func onMouseDown(_ handler: @escaping (MouseEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.MouseDown.self, handler: handler)
    }

    consuming func onMouseMove(_ handler: @escaping (MouseEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.MouseMove.self, handler: handler)
    }

    consuming func onMouseUp(_ handler: @escaping (MouseEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.MouseUp.self, handler: handler)
    }

    consuming func onKeyDown(_ handler: @escaping (KeyboardEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.KeyDown.self, handler: handler)
    }

    consuming func onInput(_ handler: @escaping (InputEvent) -> Void) -> some View {
        onEvent(DOMEventHandlers.Input.self, handler: handler)
    }
}

enum DOMEventHandlers {
    enum Click: DOMEventHandlerConfig {
        static var name: String = "click"
        typealias Event = MouseEvent
    }

    enum MouseDown: DOMEventHandlerConfig {
        static var name: String = "mousedown"
        typealias Event = MouseEvent
    }

    enum MouseMove: DOMEventHandlerConfig {
        static var name: String = "mousemove"
        typealias Event = MouseEvent
    }

    enum MouseUp: DOMEventHandlerConfig {
        static var name: String = "mouseup"
        typealias Event = MouseEvent
    }

    enum KeyDown: DOMEventHandlerConfig {
        static var name: String = "keydown"
        typealias Event = KeyboardEvent
    }

    enum Input: DOMEventHandlerConfig {
        static var name: String = "input"
        typealias Event = InputEvent
    }
}
