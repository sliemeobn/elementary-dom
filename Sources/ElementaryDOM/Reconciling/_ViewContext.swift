public struct _ViewContext {
    var environment: EnvironmentValues = .init()

    // built-in typed environment values (maybe using plain-old keys might be better?)
    var modifiers: DOMElementModifiers = .init()
    var functionDepth: Int = 0
    var parentElement: _ElementNode?

    mutating func takeModifiers() -> [any DOMElementModifier] {
        modifiers.takeModifiers()
    }

    public static var empty: Self {
        .init()
    }
}
