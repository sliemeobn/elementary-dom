/// A type that describes how to animate a value.
///
/// Conform your view to this protocol to enable custom animations.
///
/// ## Creating Custom Animation
///
/// To make a view animatable, implement the `animatableValue` property that
/// converts your view's properties into an animatable vector type:
///
/// ```swift
/// @View
/// struct MyAnimatedView {
///     var x: Double
///     var y: Double
///
///     var body: some View {
///         p { "x: \(x) y: \(y)" }
///     }
/// }
///
/// extension MyAnimatedView: Animatable {
///     var animatableValue: SIMD2<Float> {
///         get {
///             SIMD2(Float(x), Float(y))
///         }
///         set {
///             x = Double(newValue[0])
///             y = Double(newValue[1])
///         }
///     }
/// }
/// ```
public protocol Animatable {
    /// The type that represents the animatable data.
    associatedtype Value: AnimatableVectorConvertible

    /// The animatable data for this value.
    var animatableValue: Value { get set }
}

/// A type that can be converted to and from an animatable vector.
public protocol AnimatableVectorConvertible: Equatable {

    /// Creates a value from an animatable vector.
    ///
    /// - Parameter animatableVector: The animatable vector to convert from.
    ///
    /// - Note: Calling this initializer with a vector that has a mismatching dimensions
    ///   will cause a fatal error.
    init(_animatableVector animatableVector: AnimatableVector)

    /// The animatable vector representation of this value.
    var animatableVector: AnimatableVector { get }
}
