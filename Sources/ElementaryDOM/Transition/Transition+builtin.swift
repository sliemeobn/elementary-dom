public struct FadeTransition: Transition {
    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.opacity(phase.isIdentity ? 1.0 : 0.0)
    }
}

extension Transition where Self == FadeTransition {
    public static var fade: Self { FadeTransition() }
}
