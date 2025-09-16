import ElementaryMath

/// A spring animation configuration that defines the physical properties of a spring.
/// Similar to SwiftUI's Spring but uses AnimatableVector as the value type.
public struct Spring {
    /// Damping regime of the system, precomputed with an epsilon threshold.
    private enum DampingRegime {
        case underdamped, criticallyDamped, overdamped

        init(dampingRatio: Double) {
            if abs(dampingRatio - 1.0) < 1e-6 {
                self = .criticallyDamped
            } else if dampingRatio < 1.0 {
                self = .underdamped
            } else {
                self = .overdamped
            }
        }
    }

    /// The damping ratio (ζ) of the spring system.
    /// 0 = undamped, 1 = critically damped, >1 = overdamped
    public let dampingRatio: Double

    /// The natural frequency (ω₀) of the spring system in rad/s.
    public let naturalFrequency: Double

    /// pre-calculated damping regime
    private var regime: DampingRegime

    private init(dampingRatio: Double, naturalFrequency: Double) {
        self.dampingRatio = dampingRatio
        self.naturalFrequency = naturalFrequency
        self.regime = DampingRegime(dampingRatio: dampingRatio)
    }

    public init(
        mass: Double = 1.0,
        stiffness: Double,
        damping: Double,
        allowOverDamping: Bool = false
    ) {
        precondition(mass > 0, "Spring.mass must be > 0")
        precondition(stiffness > 0, "Spring.stiffness must be > 0")
        precondition(damping >= 0, "Spring.damping must be >= 0")
        let actualDamping: Double

        // Clamp damping to prevent over-damping if not allowed
        if !allowOverDamping {
            let criticalDamping = 2.0 * sqrt(stiffness * mass)
            actualDamping = min(damping, criticalDamping)
        } else {
            actualDamping = damping
        }

        // Calculate derived physics values
        self.init(
            dampingRatio: actualDamping / (2.0 * sqrt(stiffness * mass)),
            naturalFrequency: sqrt(stiffness / mass)
        )
    }

    public init(settlingDuration: Double = 0.5, bounce: Double = 0.0) {
        let clampedBounce = min(max(bounce, 0.0), 1.0)
        let safeDuration = max(settlingDuration, 1e-6)
        self.init(
            dampingRatio: 1.0 - clampedBounce,
            naturalFrequency: 2.0 * .pi / safeDuration
        )
    }

    /// Creates a spring with response and damping fraction.
    /// - Parameters:
    ///   - response: The response time of the spring.
    ///   - dampingFraction: The damping fraction (0.0 = undamped, 1.0 = critically damped).
    public init(response: Double, dampingFraction: Double = 1.0) {
        let safeResponse = max(response, 1e-6)
        let clampedDamping = max(dampingFraction, 0.0)
        self.init(
            dampingRatio: clampedDamping,
            naturalFrequency: 2.0 * .pi / safeResponse
        )
    }
}

extension Spring {
    public static var smooth: Self { smooth() }
    public static var snappy: Self { snappy() }
    public static var bouncy: Self { bouncy() }

    public static func smooth(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(settlingDuration: duration, bounce: extraBounce + 0.0)
    }

    public static func snappy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(settlingDuration: duration, bounce: extraBounce + 0.15)
    }

    public static func bouncy(duration: Double = 0.5, extraBounce: Double = 0.0) -> Self {
        .init(settlingDuration: duration, bounce: extraBounce + 0.3)
    }
}

// MARK: - CustomAnimation Conformance

extension Spring: CustomAnimation {
    public func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector? {
        // Use the initial velocity from context if available, otherwise use zero velocity
        let velocity = context.initialVelocity ?? AnimatableVector.zero(value)

        // Use stored spring physics values
        let t = time

        let result: AnimatableVector

        switch regime {
        case .criticallyDamped:
            // Critically damped
            let envelope = exp(-naturalFrequency * t)
            let factor = envelope * (1.0 + naturalFrequency * t)
            let velocityFactor = envelope * t

            result = value * factor + velocity * velocityFactor
        case .underdamped:
            // Underdamped
            let omegaD = naturalFrequency * sqrt(1.0 - dampingRatio * dampingRatio)
            let envelope = exp(-dampingRatio * naturalFrequency * t)
            let cosine = cos(omegaD * t)
            let sine = sin(omegaD * t)

            let factor = envelope * (cosine + (dampingRatio * naturalFrequency / omegaD) * sine)
            let velocityFactor = envelope * (-omegaD * sine)

            result = value * factor + velocity * (velocityFactor / naturalFrequency)
        case .overdamped:
            // Overdamped
            let r1 = -naturalFrequency * (dampingRatio + sqrt(dampingRatio * dampingRatio - 1.0))
            let r2 = -naturalFrequency * (dampingRatio - sqrt(dampingRatio * dampingRatio - 1.0))

            let c1 = (velocity + value * Float(-r2)) * Float(1.0 / (r1 - r2))
            let c2 = value + c1 * Float(-1.0)

            let factor1 = exp(r1 * t)
            let factor2 = exp(r2 * t)

            result = c1 * Float(factor1) + c2 * Float(factor2)
        }

        // Check if animation has settled (within tolerance)
        let tolerance: Float = 0.001
        let currentVelocityVector = self.velocity(value: value, time: time, context: context) ?? AnimatableVector.zero(value)
        let isSettled = isValueSettled(result, target: value, tolerance: tolerance, currentVelocity: currentVelocityVector)

        return isSettled ? nil : result
    }

    public func velocity(value: AnimatableVector, time: Double, context: AnimationContext) -> AnimatableVector? {
        let velocity = context.initialVelocity ?? AnimatableVector.zero(value)

        let t = time

        switch regime {
        case .underdamped:
            // Underdamped
            let omegaD = naturalFrequency * sqrt(1.0 - dampingRatio * dampingRatio)
            let envelope = exp(-dampingRatio * naturalFrequency * t)
            let cosine = cos(omegaD * t)
            let sine = sin(omegaD * t)

            let velocityFactor = envelope * (-dampingRatio * naturalFrequency * cosine - omegaD * sine)
            let accelerationFactor =
                envelope * (dampingRatio * naturalFrequency * omegaD * sine - omegaD * omegaD * cosine) / naturalFrequency

            return value * Float(velocityFactor) + velocity * Float(accelerationFactor)
        case .criticallyDamped, .overdamped:
            // Simplified velocity calculation for critically and overdamped cases
            return velocity * Float(exp(-naturalFrequency * t))
        }
    }

    public func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool {
        // TODO: if velocity -> merge
        true
    }

    private func isValueSettled(
        _ current: AnimatableVector,
        target: AnimatableVector,
        tolerance: Float,
        currentVelocity: AnimatableVector
    ) -> Bool {
        let positionSettled = (current - target).magnitude < tolerance
        let velocitySettled = currentVelocity.magnitude < tolerance
        return positionSettled && velocitySettled
    }
}
