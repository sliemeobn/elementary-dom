public struct Transaction {
    // TODO: either main actor or thread local for multi-threaded environments
    internal static var _current: Transaction? = nil
    internal static var lastId: UInt32 = 0

    let _id: UInt32

    public init(animation: Animation? = nil) {
        defer { Transaction.lastId &+= 1 }
        self._id = Transaction.lastId
        self.animation = animation
    }

    public var animation: Animation?
    public var disablesAnimation: Bool = false

    // TODO: extendable storage via typed keys
}

public func withTransaction<Result, Failure>(
    _ transaction: Transaction,
    _ body: () throws(Failure) -> Result
) throws(Failure) -> Result {
    let previous = Transaction._current
    Transaction._current = transaction
    defer {
        Transaction._current = previous
    }
    logTrace("withTransaction \(transaction._id)")
    return try body()
}

public func withAnimation<Result, Failure>(
    _ animation: Animation? = .default,
    _ body: () throws(Failure) -> Result
) throws(Failure) -> Result {
    try withTransaction(.init(animation: animation), body)
}
