/// A unique identifier for a reactive property.
///
/// `PropertyID` is used by the reactivity system to track which properties
/// are accessed during reactive scopes. Each reactive property is assigned a unique `PropertyID`.
///
/// You typically don't need to create `PropertyID` instances manually unless you're
/// building custom reactive primitives.
/// ```
public struct PropertyID: Hashable, Sendable, CustomStringConvertible {
    @usableFromInline
    enum _Storage: Hashable, Sendable {
        case index(Int)
        case name([UInt8])
        case objectIdentifier(ObjectIdentifier)
    }

    @usableFromInline
    let id: _Storage

    /// Creates a property identifier using a string name.
    ///
    /// - Parameter name: A unique string identifier for the property.
    @inlinable
    public init(_ name: String) {
        id = .name(Array(name.utf8))
    }

    /// Creates a property identifier using an integer index.
    ///
    /// - Parameter index: A unique integer identifier for the property.
    @inlinable
    public init(_ index: Int) {
        id = .index(index)
    }

    /// Creates a property identifier using an object identifier.
    ///
    /// - Parameter index: A unique object identifier for the property.
    @inlinable
    public init(_ index: ObjectIdentifier) {
        id = .objectIdentifier(index)
    }

    /// A string representation of the property identifier.
    ///
    /// Returns the underlying value as a string, useful for debugging and logging.
    public var description: String {
        switch id {
        case let .index(index):
            return "\(index)"
        case let .name(name):
            return String(decoding: name, as: UTF8.self)
        case let .objectIdentifier(identifier):
            return "\(identifier)"
        }
    }
}
