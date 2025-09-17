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
    public func value(target: AnimatableVector, initialVelocity: AnimatableVector, time: Double) -> AnimatableVector {
        switch regime {
        case .criticallyDamped:
            // Critically damped: starts at 0, approaches target
            let envelope = exp(-naturalFrequency * time)
            let factor = 1.0 - envelope * (1.0 + naturalFrequency * time)
            let velocityFactor = envelope * time

            return target * Float(factor) + initialVelocity * Float(velocityFactor)

        case .underdamped:
            // Underdamped: starts at 0, approaches target with oscillation
            let omegaD = naturalFrequency * sqrt(1.0 - dampingRatio * dampingRatio)
            let envelope = exp(-dampingRatio * naturalFrequency * time)
            let cosine = cos(omegaD * time)
            let sine = sin(omegaD * time)

            let factor = 1.0 - envelope * (cosine + (dampingRatio * naturalFrequency / omegaD) * sine)
            let velocityFactor = envelope * sine / omegaD

            return target * Float(factor) + initialVelocity * Float(velocityFactor)

        case .overdamped:
            // Overdamped: starts at 0, approaches target without oscillation
            let discriminant = sqrt(dampingRatio * dampingRatio - 1.0)
            let r1 = -naturalFrequency * (dampingRatio + discriminant)
            let r2 = -naturalFrequency * (dampingRatio - discriminant)

            // Solve for coefficients such that position(0) = 0 and velocity(0) = initialVelocity
            let c1 = Float(1.0 / (r1 - r2))
            let c2 = -c1

            let exp1 = exp(r1 * time)
            let exp2 = exp(r2 * time)

            // Position approaches target as exponentials decay to 0
            let decayFactor = c1 * Float(exp1) + c2 * Float(exp2)
            let velocityTerm = initialVelocity * Float((exp1 - exp2) / (r1 - r2))

            return target - target * decayFactor + velocityTerm
        }
    }

    public func velocity(target: AnimatableVector, initialVelocity: AnimatableVector, time: Double) -> AnimatableVector {
        switch regime {
        case .underdamped:
            // Underdamped velocity
            let omegaD = naturalFrequency * sqrt(1.0 - dampingRatio * dampingRatio)
            let envelope = exp(-dampingRatio * naturalFrequency * time)
            let cosine = cos(omegaD * time)
            let sine = sin(omegaD * time)

            let targetVelocityFactor = envelope * (dampingRatio * naturalFrequency * cosine + omegaD * sine)
            let initialVelocityFactor = envelope * (cosine - (dampingRatio * naturalFrequency / omegaD) * sine)

            return target * Float(targetVelocityFactor) + initialVelocity * Float(initialVelocityFactor)

        case .criticallyDamped:
            // Critically damped velocity
            let envelope = exp(-naturalFrequency * time)
            let targetVelocityFactor = envelope * naturalFrequency * naturalFrequency * time
            let initialVelocityFactor = envelope * (1.0 - naturalFrequency * time)

            return target * Float(targetVelocityFactor) + initialVelocity * Float(initialVelocityFactor)

        case .overdamped:
            // Overdamped velocity
            let discriminant = sqrt(dampingRatio * dampingRatio - 1.0)
            let r1 = -naturalFrequency * (dampingRatio + discriminant)
            let r2 = -naturalFrequency * (dampingRatio - discriminant)

            let c1 = Float(1.0 / (r1 - r2))
            let c2 = -c1

            let exp1 = exp(r1 * time)
            let exp2 = exp(r2 * time)

            let targetVelocityFactor = -(c1 * Float(r1 * exp1) + c2 * Float(r2 * exp2))
            let initialVelocityFactor = Float(r1 * exp1 - r2 * exp2) / Float(r1 - r2)

            return target * targetVelocityFactor + initialVelocity * initialVelocityFactor
        }
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

struct SpringAnimation: CustomAnimation {
    var spring: Spring

    func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector? {
        // Use the initial velocity from context if available, otherwise use zero velocity
        let velocity = context.initialVelocity ?? AnimatableVector.zero(value)
        print("animate: value: \(value) time: \(time) velocity: \(velocity)")

        let result = spring.value(target: value, initialVelocity: velocity, time: time)

        // Check if animation has settled (within tolerance)
        let tolerance: Float = 0.001
        let currentVelocityVector = self.velocity(value: value, time: time, context: context) ?? AnimatableVector.zero(value)
        let isSettled = isValueSettled(result, target: value, tolerance: tolerance, currentVelocity: currentVelocityVector)

        return isSettled ? nil : result
    }

    func velocity(value: AnimatableVector, time: Double, context: AnimationContext) -> AnimatableVector? {
        let velocity = context.initialVelocity ?? AnimatableVector.zero(value)

        return spring.velocity(target: value, initialVelocity: velocity, time: time)
    }

    public func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool {
        let velocity = previous.velocity(value: value, time: time, context: context)
        context.initialVelocity = velocity

        return true
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
