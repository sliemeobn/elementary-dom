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

    enum KeyDown: DOMEventHandlerConfig {
        static var name: String = "keydown"
        typealias Event = KeyboardEvent
    }

    enum Input: DOMEventHandlerConfig {
        static var name: String = "input"
        typealias Event = InputEvent
    }
}
