import ElementaryMath

// TODO: maybe this can be replaced with Spans of floats somehow
public enum AnimatableVector {
    case d0
    case d1(Float)
    case d2(Float, Float)
    case d4(SIMD4<Float>)
    case d8(SIMD4<Float>, SIMD4<Float>)
}

extension AnimatableVector {
    internal var isEmpty: Bool {
        switch self {
        case .d0:
            return true
        default:
            return false
        }
    }
}

extension AnimatableVector: AnimatableVectorConvertible {
    public init(_ animatableVector: AnimatableVector) {
        self = animatableVector
    }

    public var animatableVector: AnimatableVector {
        self
    }
}

extension AnimatableVector: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.d0, .d0):
            return true
        case (.d1(let l1), .d1(let r1)):
            return l1 == r1
        case (.d2(let l1, let l2), .d2(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.d4(let l1), .d4(let r1)):
            return l1 == r1
        case (.d8(let l1, let l2), .d8(let r1, let r2)):
            return l1 == r1 && l2 == r2
        default:
            return false
        }
    }
}

extension AnimatableVector {
    public static func zero(_ vector: borrowing Self) -> Self {
        switch vector {
        case .d0:
            return .d0
        case .d1(_):
            return .d1(0)
        case .d2(_, _):
            return .d2(0, 0)
        case .d4(_):
            return .d4(SIMD4<Float>(repeating: 0))
        case .d8(_, _):
            return .d8(SIMD4<Float>(repeating: 0), SIMD4<Float>(repeating: 0))
        }
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.d0, .d0):
            return .d0
        case (.d1(let l1), .d1(let r1)):
            return .d1(l1 + r1)
        case (.d2(let l1, let l2), .d2(let r1, let r2)):
            return .d2(l1 + r1, l2 + r2)
        case (.d4(let l1), .d4(let r1)):
            return .d4(l1 + r1)
        case (.d8(let l1, let l2), .d8(let r1, let r2)):
            return .d8(l1 + r1, l2 + r2)
        default:
            fatalError("mismatching dimensions")
        }
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    public static func * (lhs: Self, rhs: Float) -> Self {
        switch lhs {
        case .d0:
            return .d0
        case .d1(let l1):
            return .d1(l1 * rhs)
        case .d2(let l1, let l2):
            return .d2(l1 * rhs, l2 * rhs)
        case .d4(let l1):
            return .d4(l1 * rhs)
        case .d8(let l1, let l2):
            return .d8(l1 * rhs, l2 * rhs)
        }
    }

    public static func * (lhs: Self, rhs: Double) -> Self {
        lhs * Float(rhs)
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.d0, .d0):
            return .d0
        case (.d1(let l1), .d1(let r1)):
            return .d1(l1 - r1)
        case (.d2(let l1, let l2), .d2(let r1, let r2)):
            return .d2(l1 - r1, l2 - r2)
        case (.d4(let l1), .d4(let r1)):
            return .d4(l1 - r1)
        case (.d8(let l1, let l2), .d8(let r1, let r2)):
            return .d8(l1 - r1, l2 - r2)
        default:
            fatalError("mismatching dimensions")
        }
    }

    /// Calculates the magnitude (length) of the vector
    public var magnitude: Float {
        switch self {
        case .d0:
            return 0
        case .d1(let x):
            return abs(x)
        case .d2(let x, let y):
            return sqrtf(x * x + y * y)
        case .d4(let v):
            return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w)
        case .d8(let v1, let v2):
            let mag1 = v1.x * v1.x + v1.y * v1.y + v1.z * v1.z + v1.w * v1.w
            let mag2 = v2.x * v2.x + v2.y * v2.y + v2.z * v2.z + v2.w * v2.w
            return sqrtf(mag1 + mag2)
        }
    }
}
