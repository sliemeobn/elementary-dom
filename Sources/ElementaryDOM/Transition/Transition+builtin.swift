public struct FadeTransition: Transition {
    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.opacity(phase.isIdentity ? 1.0 : 0)
    }
}

public struct SlideInTransition: Transition {
    public func body(content: Content, phase: TransitionPhase) -> some View {
        content.offset(x: phase.isIdentity ? 0 : 100)
    }
}

extension Transition where Self == FadeTransition {
    public static var fade: Self { FadeTransition() }
}

extension Transition where Self == SlideInTransition {
    public static var slideIn: Self { SlideInTransition() }
}
