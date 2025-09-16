public protocol Animatable {
    associatedtype Value: AnimatableVectorConvertible
    var animatableValue: Value { get set }
}

public protocol AnimatableVectorConvertible {
    init(_ animatableVector: AnimatableVector)
    var animatableVector: AnimatableVector { get }
}

public struct Animation {
    enum StoredAnimation {
        case spring(Spring)
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
        self.storage = .spring(spring)
    }

    public init(_ customAnimation: some CustomAnimation) {
        self.storage = .any(AnyAnimation(customAnimation))
    }

    func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector? {
        let time = time * speed + delay

        switch storage {
        case .spring(let spring):
            return spring.animate(value: value, time: time, context: &context)
        case .timingFunction(let timingFunction):
            return timingFunction.animate(value: value, time: time, context: &context)
        case .any(let anyAnimation):
            return anyAnimation.animate(value, time, &context)
        }
    }

    func velocity(value: AnimatableVector, time: Double, context: borrowing AnimationContext) -> AnimatableVector? {
        switch storage {
        case .spring(let spring):
            return spring.velocity(value: value, time: time, context: context)
        case .timingFunction(let timingFunction):
            return timingFunction.velocity(value: value, time: time, context: context)
        case .any(let anyAnimation):
            return anyAnimation.velocity(value, time, context)
        }
    }

    func shouldMerge(previous: Animation, value: AnimatableVector, time: Double, context: inout AnimationContext) -> Bool {
        switch storage {
        case .spring(let spring):
            return spring.shouldMerge(previous: previous, value: value, time: time, context: &context)
        case .timingFunction(let timingFunction):
            return timingFunction.shouldMerge(previous: previous, value: value, time: time, context: &context)
        case .any(let anyAnimation):
            return anyAnimation.shouldMerge(previous, value, time, &context)
        }
    }
}

public struct AnimationContext {
    var initialVelocity: AnimatableVector?
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
