public protocol Transition {
    associatedtype Body: View
    typealias Content = PlaceholderContentView<Self>

    @HTMLBuilder func body(content: Content, phase: TransitionPhase) -> Body
}

public enum TransitionPhase: Equatable, Sendable {
    case willAppear
    case identity
    case didDisappear

    public var isIdentity: Bool {
        self == .identity
    }

    public var value: Double {
        switch self {
        case .willAppear: -1.0
        case .identity: 0.0
        case .didDisappear: 1.0
        }
    }
}
