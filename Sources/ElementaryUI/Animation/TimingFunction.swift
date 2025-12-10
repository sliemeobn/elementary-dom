public struct UnitCurve {
    private enum Storage {
        case linear
        case bezier(x1: Float, y1: Float, x2: Float, y2: Float)
    }

    private let storage: Storage

    public func value(at time: Double) -> Float {
        let t = clamped(time)
        switch storage {
        case .linear:
            return t
        case let .bezier(_, y1, _, y2):
            let oneMinusT = 1.0 - t
            let t2 = t * t
            let t3 = t2 * t
            let oneMinusT2 = oneMinusT * oneMinusT
            return 3.0 * oneMinusT2 * t * y1 + 3.0 * oneMinusT * t2 * y2 + t3
        }
    }

    public func velocity(at time: Double) -> Float {
        let t = clamped(time)
        switch storage {
        case .linear:
            return 1.0
        case let .bezier(_, y1, _, y2):
            let oneMinusT = 1.0 - t
            let t2 = t * t
            let oneMinusT2 = oneMinusT * oneMinusT
            // Derivative of cubic bezier curve (normalized velocity)
            return 3.0 * oneMinusT2 * y1 + 6.0 * oneMinusT * t * (y2 - y1) + 3.0 * t2 * (1.0 - y2)
        }
    }

    private func clamped(_ value: Double) -> Float {
        Float(min(max(value, 0.0), 1.0))
    }
}

extension UnitCurve {
    // Linear cubic-bezier fast path: cubic-bezier(1/3, 1/3, 2/3, 2/3)
    public static let linear: Self = .init(storage: .linear)

    public static func bezier(x1: Float, y1: Float, x2: Float, y2: Float) -> Self {
        .init(storage: .bezier(x1: x1, y1: y1, x2: x2, y2: y2))
    }

    public static let easeInOut: Self = .bezier(x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)
    public static let easeIn: Self = .bezier(x1: 0.42, y1: 0.0, x2: 1.0, y2: 1.0)
    public static let easeOut: Self = .bezier(x1: 0.0, y1: 0.0, x2: 0.58, y2: 1.0)
}

struct TimingFunction {
    var curve: UnitCurve
    var duration: Double
}

extension TimingFunction: CustomAnimation {
    func animate(value: AnimatableVector, time: Double, context: inout AnimationContext) -> AnimatableVector? {
        guard time <= duration else {
            return nil
        }

        let t = time / duration
        let factor = curve.value(at: t)
        return value * factor
    }

    func velocity(value: AnimatableVector, time: Double, context: AnimationContext) -> AnimatableVector? {
        guard time <= duration else {
            return nil
        }

        let t = time / duration
        let velocityFactor = curve.velocity(at: t)
        return value * velocityFactor
    }
}
