/// A vector of values that can be animated.
public struct AnimatableVector {
    @usableFromInline
    enum Storage {
        case d0
        case d1(Float)
        case d2(SIMD2<Float>)
        case d4(SIMD4<Float>)
        case d8(SIMD8<Float>)
    }

    @usableFromInline
    var storage: Storage

    @usableFromInline
    init(_ storage: Storage) {
        self.storage = storage
    }

    static var empty: Self {
        .init(.d0)
    }
}

extension AnimatableVector {
    internal var isEmpty: Bool {
        switch storage {
        case .d0:
            return true
        default:
            return false
        }
    }
}

extension AnimatableVector: AnimatableVectorConvertible {
    public init(_animatableVector animatableVector: AnimatableVector) {
        self = animatableVector
    }

    public var animatableVector: AnimatableVector {
        self
    }
}

extension AnimatableVector: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.storage, rhs.storage) {
        case (.d0, .d0):
            return true
        case (.d1(let l1), .d1(let r1)):
            return l1 == r1
        case (.d2(let l1), .d2(let r1)):
            return l1 == r1
        case (.d4(let l1), .d4(let r1)):
            return l1 == r1
        case (.d8(let l1), .d8(let r1)):
            return l1 == r1
        default:
            return false
        }
    }
}

extension AnimatableVector {
    @inlinable
    public static func zero(_ vector: borrowing Self) -> Self {
        switch vector.storage {
        case .d0:
            return .init(.d0)
        case .d1(_):
            return .init(.d1(0))
        case .d2(_):
            return .init(.d2(SIMD2<Float>(repeating: 0)))
        case .d4(_):
            return .init(.d4(SIMD4<Float>(repeating: 0)))
        case .d8(_):
            return .init(.d8(SIMD8<Float>(repeating: 0)))
        }
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs.storage, rhs.storage) {
        case (.d0, .d0):
            return .init(.d0)
        case (.d1(let l1), .d1(let r1)):
            return .init(.d1(l1 + r1))
        case (.d2(let l1), .d2(let r1)):
            return .init(.d2(l1 + r1))
        case (.d4(let l1), .d4(let r1)):
            return .init(.d4(l1 + r1))
        case (.d8(let l1), .d8(let r1)):
            return .init(.d8(l1 + r1))
        default:
            fatalError("mismatching dimensions")
        }
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    @inlinable
    public static func * (lhs: Self, rhs: Float) -> Self {
        switch lhs.storage {
        case .d0:
            return .init(.d0)
        case .d1(let l1):
            return .init(.d1(l1 * rhs))
        case .d2(let l1):
            return .init(.d2(l1 * rhs))
        case .d4(let l1):
            return .init(.d4(l1 * rhs))
        case .d8(let l1):
            return .init(.d8(l1 * rhs))
        }
    }

    @inlinable
    public static func * (lhs: Self, rhs: Double) -> Self {
        lhs * Float(rhs)
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        switch (lhs.storage, rhs.storage) {
        case (.d0, .d0):
            return .init(.d0)
        case (.d1(let l1), .d1(let r1)):
            return .init(.d1(l1 - r1))
        case (.d2(let l1), .d2(let r1)):
            return .init(.d2(l1 - r1))
        case (.d4(let l1), .d4(let r1)):
            return .init(.d4(l1 - r1))
        case (.d8(let l1), .d8(let r1)):
            return .init(.d8(l1 - r1))
        default:
            fatalError("mismatching dimensions")
        }
    }

    /// Calculates the magnitude (length) of the vector
    @inlinable
    public var magnitude: Float {
        switch storage {
        case .d0:
            return 0
        case .d1(let x):
            return abs(x)
        case .d2(let x):
            return (x * x).sum().squareRoot()
        case .d4(let v):
            return (v * v).sum().squareRoot()
        case .d8(let v):
            return (v * v).sum().squareRoot()
        }
    }
}
