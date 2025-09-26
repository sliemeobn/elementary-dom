public struct Angle: Equatable, Sendable {
    var degrees: Double
    var radians: Double {
        get {
            degrees * .pi / 180
        }
        set {
            degrees = newValue * 180 / .pi
        }
    }

    public static func radians(_ radians: Double) -> Angle {
        // degrees are probably more common in everyday usage
        Angle(degrees: radians * 180 / .pi)
    }

    public static func degrees(_ degrees: Double) -> Angle {
        Angle(degrees: degrees)
    }
}

public struct UnitPoint: Equatable, Sendable {
    var x: Float
    var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public static let center: UnitPoint = UnitPoint(x: 0.5, y: 0.5)
    public static let topLeading: UnitPoint = UnitPoint(x: 0, y: 0)
    public static let top: UnitPoint = UnitPoint(x: 0.5, y: 0)
    public static let topTrailing: UnitPoint = UnitPoint(x: 1, y: 0)
    public static let leading: UnitPoint = UnitPoint(x: 0, y: 0.5)
    public static let trailing: UnitPoint = UnitPoint(x: 1, y: 0.5)
    public static let bottomLeading: UnitPoint = UnitPoint(x: 0, y: 1)
    public static let bottom: UnitPoint = UnitPoint(x: 0.5, y: 1)
    public static let bottomTrailing: UnitPoint = UnitPoint(x: 1, y: 1)

    internal var isCenter: Bool {
        x == 0.5 && y == 0.5
    }

    internal var cssXPercent: Float {
        x * 100 - 50
    }

    internal var cssYPercent: Float {
        y * 100 - 50
    }
}

struct CSSTransform: CSSPropertyValue {
    static var styleKey: String = "transform"

    enum AnyFunction {
        case rotation(CSSRotation)
        case translation(CSSTranslation)
    }

    var value: [AnyFunction]

    static var none: CSSTransform {
        CSSTransform()
    }

    private init() {
        self.value = []
    }

    init(_ value: AnyFunction) {
        self.value = [value]
    }

    var cssString: String {
        guard !value.isEmpty else { return "none" }
        return value.map { $0.cssString }.joined(separator: " ")
    }

    mutating func combineWith(_ other: consuming CSSTransform) {
        value.append(contentsOf: other.value)
    }
}

extension CSSTransform.AnyFunction {
    var cssString: String {
        switch self {
        case .rotation(let rotation):
            if rotation.anchor.isCenter {
                "rotate(\(rotation.angle.degrees)deg)"
            } else {
                """
                translate(\(rotation.anchor.cssXPercent)%, \(rotation.anchor.cssYPercent)%) rotate(\(rotation.angle.degrees)deg)  translate(\(-rotation.anchor.cssXPercent)%, \(-rotation.anchor.cssYPercent)%)
                """
            }
        case .translation(let translation):
            "translate(\(translation.x)px, \(translation.y)px)"
        }
    }
}

struct CSSRotation: CSSAnimatable {
    var angle: Angle
    var anchor: UnitPoint

    init(angle: Angle, anchor: UnitPoint) {
        self.angle = angle
        self.anchor = anchor
    }

    var isIdentity: Bool {
        // TODO: epsilon?
        angle.degrees == 0
    }

    var cssValue: CSSTransform {
        guard !isIdentity else { return .none }
        return CSSTransform(.rotation(self))
    }

    init(_ animatableVector: AnimatableVector) {
        guard case .d4(let value) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self.angle = Angle(degrees: Double(value[0]))
        self.anchor = UnitPoint(x: value[1], y: value[2])
    }

    var animatableVector: AnimatableVector {
        .d4(SIMD4<Float>(Float(angle.degrees), Float(anchor.x), Float(anchor.y), 0))
    }
}

struct CSSTranslation: CSSAnimatable {
    var x: Float
    var y: Float

    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    var cssValue: CSSTransform {
        CSSTransform(.translation(self))
    }

    init(_ animatableVector: AnimatableVector) {
        guard case .d2(let x, let y) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self.x = x
        self.y = y
    }

    var animatableVector: AnimatableVector {
        .d2(x, y)
    }
}

struct CSSOpacity {
    var value: Double

    init(value: Double) {
        self.value = min(max(value, 0), 1)
    }
}

extension CSSOpacity: CSSAnimatable {
    var cssValue: CSSOpacity { self }
    init(_ animatableVector: AnimatableVector) {
        guard case .d1(let value) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self.value = Double(value)
    }

    var animatableVector: AnimatableVector {
        .d1(Float(value))
    }
}

extension CSSOpacity: CSSPropertyValue {
    static var styleKey: String = "opacity"

    var cssString: String { "\(value)" }

    mutating func combineWith(_ other: CSSOpacity) {
        value *= other.value
    }
}
