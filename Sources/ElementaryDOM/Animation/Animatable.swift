/// A protocol for types that can be animated.
/// ```
public protocol Animatable {
    /// The type that represents the animatable data.
    associatedtype Value: AnimatableVectorConvertible

    /// The animatable data for this value.
    var animatableValue: Value { get set }
}

/// A protocol for types that can be converted to and from an animatable vector.
///
/// Types conforming to this protocol can be used with the animation system.
/// The protocol provides conversion between Swift types and ``AnimatableVector``,
/// which the framework uses for interpolation.
///
/// ## Implementation
///
/// ```swift
/// struct Size: AnimatableVectorConvertible {
///     var width: Float
///     var height: Float
///
///     var animatableVector: AnimatableVector {
///         .d2(width, height)
///     }
///
///     init(_ vector: AnimatableVector) {
///         guard case .d2(let w, let h) = vector else {
///             fatalError("Invalid vector dimension")
///         }
///         self.width = w
///         self.height = h
///     }
/// }
/// ```
public protocol AnimatableVectorConvertible: Equatable {
    /// Creates a value from an animatable vector.
    ///
    /// - Parameter animatableVector: The vector representation to convert from.
    init(_ animatableVector: AnimatableVector)

    /// The animatable vector representation of this value.
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
