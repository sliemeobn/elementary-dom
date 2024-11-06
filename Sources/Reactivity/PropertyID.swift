public struct PropertyID: Hashable, Sendable {
    @usableFromInline
    enum _Storage: Hashable, Sendable {
        case index(Int)
        case name([UInt8])
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
}
