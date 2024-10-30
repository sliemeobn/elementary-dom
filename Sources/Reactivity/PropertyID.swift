public struct PropertyID: Hashable, Sendable {
    let id: [UInt8]

    public init(_ name: String) {
        id = Array(name.utf8)
    }
}
