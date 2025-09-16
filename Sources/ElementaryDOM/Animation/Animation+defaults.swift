extension Animation {
    public static var linear: Self {
        .init(curve: .linear, duration: 0.35)
    }

    public static func linear(duration: Double) -> Self {
        .init(curve: .linear, duration: duration)
    }

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
}
