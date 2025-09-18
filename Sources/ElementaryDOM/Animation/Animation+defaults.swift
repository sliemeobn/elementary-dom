extension Animation {
    public static var smooth: Self {
        .init(spring: .smooth)
    }

    public static var snappy: Self {
        .init(spring: .snappy)
    }

    public static var bouncy: Self {
        .init(spring: .bouncy)
    }

    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .smooth(duration: duration, extraBounce: extraBounce))
    }

    public static func snappy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .snappy(duration: duration, extraBounce: extraBounce))
    }

    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .bouncy(duration: duration, extraBounce: extraBounce))
    }

    public static let `default`: Self = .smooth
}

extension Animation {
    public static func linear(duration: Double) -> Self {
        .init(curve: .linear, duration: duration)
    }

    public static func easeInOut(duration: Double) -> Self {
        .init(curve: .easeInOut, duration: duration)
    }

    public static func easeIn(duration: Double) -> Self {
        .init(curve: .easeIn, duration: duration)
    }

    public static func easeOut(duration: Double) -> Self {
        .init(curve: .easeOut, duration: duration)
    }

    public static var linear: Self {
        .init(curve: .linear, duration: 0.35)
    }

    public static var easeInOut: Self {
        .init(curve: .easeInOut, duration: 0.35)
    }

    public static var easeIn: Self {
        .init(curve: .easeIn, duration: 0.35)
    }

    public static var easeOut: Self {
        .init(curve: .easeOut, duration: 0.35)
    }

    public static func bezier(x1: Float, y1: Float, x2: Float, y2: Float, duration: Double) -> Self {
        .init(curve: .bezier(x1: x1, y1: y1, x2: x2, y2: y2), duration: duration)
    }
}
