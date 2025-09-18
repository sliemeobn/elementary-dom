public protocol Animatable {
    associatedtype Value: AnimatableVectorConvertible
    var animatableValue: Value { get set }
}

public protocol AnimatableVectorConvertible: Equatable {
    init(_ animatableVector: AnimatableVector)
    var animatableVector: AnimatableVector { get }
}

extension AnimatableVectorConvertible where Self: Animatable, Value == Self {
    public typealias Value = Self
    public var animatableValue: Self {
        get { self }
        set { self = newValue }
    }
}

extension Double: AnimatableVectorConvertible, Animatable {
    public init(_ animatableVector: AnimatableVector) {
        guard case .d1(let value) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self = Double(value)
    }

    public var animatableVector: AnimatableVector {
        .d1(Float(self))
    }
}

extension Float: AnimatableVectorConvertible, Animatable {
    public init(_ animatableVector: AnimatableVector) {
        guard case .d1(let value) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self = value
    }

    public var animatableVector: AnimatableVector {
        .d1(self)
    }
}

struct EmptyAnimatableData: AnimatableVectorConvertible {
    init() {}

    init(_ animatableVector: AnimatableVector) {
        guard case .d0 = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
    }

    var animatableVector: AnimatableVector {
        .d0
    }
}
