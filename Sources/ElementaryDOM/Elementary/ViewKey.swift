public enum _ViewKey: Equatable, Hashable, CustomStringConvertible {
    case structure(Int)
    case explicit(String)

    static var falseKey: Self { .structure(0) }
    static var trueKey: Self { .structure(1) }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.structure(l), .structure(r)): return l == r
        case let (.explicit(l), .explicit(r)): return l.utf8Equals(r)
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .structure(index):
            index.hash(into: &hasher)
        case let .explicit(key):
            key.hash(into: &hasher)
        }
    }

    public var description: String {
        switch self {
        case let .structure(index): return "structure:(\(index))"
        case let .explicit(key): return key
        }
    }
}
