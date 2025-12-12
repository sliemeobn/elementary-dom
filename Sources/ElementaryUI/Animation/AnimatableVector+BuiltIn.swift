extension Float: AnimatableVectorConvertible {
    @inlinable
    public init(_animatableVector animatableVector: AnimatableVector) {
        guard case .d1(let value) = animatableVector.storage else {
            fatalError("Unsupported animatable vector in Float initializer")
        }
        self = value
    }

    @inlinable
    public var animatableVector: AnimatableVector {
        .init(.d1(self))
    }
}

extension Double: AnimatableVectorConvertible {
    @inlinable
    public init(_animatableVector animatableVector: AnimatableVector) {
        self = Double(Float(_animatableVector: animatableVector))
    }

    @inlinable
    public var animatableVector: AnimatableVector {
        Float(self).animatableVector
    }
}

extension SIMD2<Float>: AnimatableVectorConvertible {
    @inlinable
    public init(_animatableVector animatableVector: AnimatableVector) {
        guard case .d2(let value) = animatableVector.storage else {
            fatalError("Unsupported animatable vector in SIMD2<Float> initializer")
        }
        self = value
    }

    @inlinable
    public var animatableVector: AnimatableVector {
        .init(.d2(self))
    }
}

extension SIMD4<Float>: AnimatableVectorConvertible {
    @inlinable
    public init(_animatableVector animatableVector: AnimatableVector) {
        guard case .d4(let value) = animatableVector.storage else {
            fatalError("Unsupported animatable vector in SIMD4<Float> initializer")
        }
        self = value
    }

    @inlinable
    public var animatableVector: AnimatableVector {
        .init(.d4(self))
    }
}

extension SIMD8<Float>: AnimatableVectorConvertible {
    @inlinable
    public init(_animatableVector animatableVector: AnimatableVector) {
        guard case .d8(let value) = animatableVector.storage else {
            fatalError("Unsupported animatable vector in SIMD8<Float> initializer")
        }
        self = value
    }

    @inlinable
    public var animatableVector: AnimatableVector {
        .init(.d8(self))
    }
}
