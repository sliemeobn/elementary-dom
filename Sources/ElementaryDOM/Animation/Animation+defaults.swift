extension Animation {
    /// A smooth spring animation with default parameters.
    ///
    /// Creates a spring animation with no bounce, ideal for most UI transitions.
    ///
    /// ```swift
    /// withAnimation(.smooth) {
    ///     isExpanded = true
    /// }
    /// ```
    public static var smooth: Self {
        .init(spring: .smooth)
    }

    /// A snappy spring animation with default parameters.
    ///
    /// Creates a spring animation with a small amount of bounce, providing
    /// responsive feedback for interactive elements.
    ///
    /// ```swift
    /// withAnimation(.snappy) {
    ///     scale = 1.2
    /// }
    /// ```
    public static var snappy: Self {
        .init(spring: .snappy)
    }

    /// A bouncy spring animation with default parameters.
    ///
    /// Creates a spring animation with noticeable bounce, adding playful
    /// character to animations.
    ///
    /// ```swift
    /// withAnimation(.bouncy) {
    ///     position = targetPosition
    /// }
    /// ```
    public static var bouncy: Self {
        .init(spring: .bouncy)
    }

    /// A smooth spring animation with customizable duration and bounce.
    ///
    /// - Parameters:
    ///   - duration: The approximate duration of the animation in seconds. Default is 0.5.
    ///   - extraBounce: Additional bounce added to the base smooth animation.
    ///     Positive values add bounce, negative values reduce it.
    /// - Returns: A smooth spring animation with the specified parameters.
    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .smooth(duration: duration, extraBounce: extraBounce))
    }

    /// A snappy spring animation with customizable duration and bounce.
    ///
    /// - Parameters:
    ///   - duration: The approximate duration of the animation in seconds. Default is 0.5.
    ///   - extraBounce: Additional bounce added to the base snappy animation.
    ///     Positive values add more bounce, negative values reduce it.
    /// - Returns: A snappy spring animation with the specified parameters.
    public static func snappy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .snappy(duration: duration, extraBounce: extraBounce))
    }

    /// A bouncy spring animation with customizable duration and bounce.
    ///
    /// - Parameters:
    ///   - duration: The approximate duration of the animation in seconds. Default is 0.5.
    ///   - extraBounce: Additional bounce added to the base bouncy animation.
    ///     Positive values add even more bounce, negative values reduce it.
    /// - Returns: A bouncy spring animation with the specified parameters.
    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(spring: .bouncy(duration: duration, extraBounce: extraBounce))
    }

    /// The default animation used when no animation is explicitly specified.
    ///
    /// Currently set to ``smooth``.
    public static let `default`: Self = .smooth
}

extension Animation {
    /// A linear timing curve animation with the specified duration.
    ///
    /// Creates an animation that progresses at a constant rate from start to finish.
    ///
    /// ```swift
    /// withAnimation(.linear(duration: 1.0)) {
    ///     rotation = 360
    /// }
    /// ```
    ///
    /// - Parameter duration: The duration of the animation in seconds.
    /// - Returns: A linear animation with the specified duration.
    public static func linear(duration: Double) -> Self {
        .init(curve: .linear, duration: duration)
    }

    /// An ease-in-out timing curve animation with the specified duration.
    ///
    /// Creates an animation that starts slowly, accelerates in the middle,
    /// and slows down at the end.
    ///
    /// ```swift
    /// withAnimation(.easeInOut(duration: 0.5)) {
    ///     opacity = 1.0
    /// }
    /// ```
    ///
    /// - Parameter duration: The duration of the animation in seconds.
    /// - Returns: An ease-in-out animation with the specified duration.
    public static func easeInOut(duration: Double) -> Self {
        .init(curve: .easeInOut, duration: duration)
    }

    /// An ease-in timing curve animation with the specified duration.
    ///
    /// Creates an animation that starts slowly and accelerates towards the end.
    ///
    /// ```swift
    /// withAnimation(.easeIn(duration: 0.3)) {
    ///     scale = 0
    /// }
    /// ```
    ///
    /// - Parameter duration: The duration of the animation in seconds.
    /// - Returns: An ease-in animation with the specified duration.
    public static func easeIn(duration: Double) -> Self {
        .init(curve: .easeIn, duration: duration)
    }

    /// An ease-out timing curve animation with the specified duration.
    ///
    /// Creates an animation that starts quickly and decelerates towards the end.
    ///
    /// ```swift
    /// withAnimation(.easeOut(duration: 0.3)) {
    ///     position = finalPosition
    /// }
    /// ```
    ///
    /// - Parameter duration: The duration of the animation in seconds.
    /// - Returns: An ease-out animation with the specified duration.
    public static func easeOut(duration: Double) -> Self {
        .init(curve: .easeOut, duration: duration)
    }

    /// A linear timing curve animation with a default duration of 0.35 seconds.
    public static var linear: Self {
        .init(curve: .linear, duration: 0.35)
    }

    /// An ease-in-out timing curve animation with a default duration of 0.35 seconds.
    public static var easeInOut: Self {
        .init(curve: .easeInOut, duration: 0.35)
    }

    /// An ease-in timing curve animation with a default duration of 0.35 seconds.
    public static var easeIn: Self {
        .init(curve: .easeIn, duration: 0.35)
    }

    /// An ease-out timing curve animation with a default duration of 0.35 seconds.
    public static var easeOut: Self {
        .init(curve: .easeOut, duration: 0.35)
    }

    /// A cubic bezier timing curve animation.
    ///
    /// Creates an animation with a custom cubic bezier curve. Control points define
    /// the shape of the timing curve.
    ///
    /// ```swift
    /// // Custom ease curve
    /// withAnimation(.bezier(x1: 0.25, y1: 0.1, x2: 0.25, y2: 1.0, duration: 0.5)) {
    ///     transform = targetTransform
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - x1: The x-coordinate of the first control point (0.0 to 1.0).
    ///   - y1: The y-coordinate of the first control point.
    ///   - x2: The x-coordinate of the second control point (0.0 to 1.0).
    ///   - y2: The y-coordinate of the second control point.
    ///   - duration: The duration of the animation in seconds.
    /// - Returns: A bezier curve animation with the specified parameters.
    public static func bezier(x1: Float, y1: Float, x2: Float, y2: Float, duration: Double) -> Self {
        .init(curve: .bezier(x1: x1, y1: y1, x2: x2, y2: y2), duration: duration)
    }
}
