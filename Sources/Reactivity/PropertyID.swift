public struct PropertyID: Hashable, Sendable, CustomStringConvertible {
    @usableFromInline
    enum _Storage: Hashable, Sendable {
        case index(Int)
        case name([UInt8])
        case objectIdentifier(ObjectIdentifier)
    }

    @usableFromInline
    let id: _Storage

    @inlinable
    public init(_ name: String) {
        id = .name(Array(name.utf8))
    }

    @inlinable
    public init(_ index: Int) {
        id = .index(index)
    }

    @inlinable
    public init(_ index: ObjectIdentifier) {
        id = .objectIdentifier(index)
    }

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
