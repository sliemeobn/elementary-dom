public struct Animation {
    enum StoredAnimation {
        case spring(SpringAnimation)
        case timingFunction(TimingFunction)
        case any(AnyAnimation)
    }

    var storage: StoredAnimation
    var speed: Double = 1
    var delay: Double = 0

    init(curve: UnitCurve, duration: Double) {
        self.storage = .timingFunction(TimingFunction(curve: curve, duration: duration))
    }

    init(spring: Spring) {
        self.storage = .spring(SpringAnimation(spring: spring))
    }

    public init(_ customAnimation: some CustomAnimation) {
        self.storage = .any(AnyAnimation(customAnimation))
    }

    func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector? {
        let localTime = localTime(time)

        guard localTime >= 0 else { return AnimatableVector.zero(value) }

        switch storage {
        case .spring(let spring):
            return spring.animate(value: value, time: localTime, context: &context)
        case .timingFunction(let timingFunction):
            return timingFunction.animate(value: value, time: localTime, context: &context)
        case .any(let anyAnimation):
            return anyAnimation.animate(value, localTime, &context)
        }
    }

    func velocity(value: AnimatableVector, time: Double, context: borrowing AnimationContext) -> AnimatableVector? {
        let localTime = localTime(time)

        guard localTime >= 0 else { return AnimatableVector.zero(value) }

        switch storage {
        case .spring(let spring):
            return spring.velocity(value: value, time: localTime, context: context)
        case .timingFunction(let timingFunction):
            return timingFunction.velocity(value: value, time: localTime, context: context)
        case .any(let anyAnimation):
            return anyAnimation.velocity(value, localTime, context)
        }
    }

    func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool {
        let localTime = localTime(time)

        guard localTime >= 0 else { return true }

        switch storage {
        case .spring(let spring):
            return spring.shouldMerge(previous: previous, value: value, time: time, context: &context)
        case .timingFunction(let timingFunction):
            return timingFunction.shouldMerge(previous: previous, value: value, time: time, context: &context)
        case .any(let anyAnimation):
            return anyAnimation.shouldMerge(previous, value, time, &context)
        }
    }

    @inline(__always)
    private func localTime(_ time: Double) -> Double {
        (time - delay) * speed
    }
}

public extension Animation {
    consuming func delay(_ delay: Double) -> Self {
        self.delay = delay + self.delay
        return self
    }

    consuming func speed(_ speed: Double) -> Self {
        guard speed != 0 else {
            self.speed = 0
            return self
        }

        self.delay = self.delay / speed
        self.speed = speed * self.speed
        return self
    }
}

public struct AnimationContext {
    var initialVelocity: AnimatableVector?
    var isLogicallyComplete: Bool = false
    //TODO: provide container for custom values
}

public protocol CustomAnimation {
    func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector?
    func velocity(value: AnimatableVector, time: Double, context: borrowing AnimationContext) -> AnimatableVector?
    func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool
}

extension CustomAnimation {
    func velocity(at time: Double, context: borrowing AnimationContext) -> AnimatableVector? { nil }
    func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool { false }
}

struct AnyAnimation {
    var animate: (AnimatableVector, Double, inout AnimationContext) -> AnimatableVector?
    var velocity: (AnimatableVector, Double, borrowing AnimationContext) -> AnimatableVector?
    var shouldMerge: (Animation, AnimatableVector, Double, inout AnimationContext) -> Bool

    init(_ customAnimation: some CustomAnimation) {
        self.animate = customAnimation.animate
        self.velocity = customAnimation.velocity
        self.shouldMerge = customAnimation.shouldMerge
    }
}
