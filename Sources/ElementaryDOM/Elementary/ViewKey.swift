public struct _ViewKey: Equatable, Hashable, CustomStringConvertible {

    // NOTE: this was an enum once, but maybe we don't need this? in any case, let's keep the option for mutiple values here open
    private let value: String

    public init(value: String) {
        self.value = value
    }

    public init<T: LosslessStringConvertible>(_ value: T) {
        self.value = value.description
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value.utf8Equals(rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        value.withContiguousStorageIfAvailable { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
    }

    public var description: String {
        value
    }
}
