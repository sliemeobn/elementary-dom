public protocol __ViewEquatable {
    static func __arePropertiesEqual(a: borrowing Self, b: borrowing Self) -> Bool
}

public enum __ViewProperty {}

public extension __ViewProperty {
    @inlinable
    static func areKnownEqual<V>(_ lhs: borrowing V, _ rhs: borrowing V) -> Bool {
        false
    }

    @inlinable
    static func areKnownEqual<V: ReactiveObject>(_ lhs: V, _ rhs: V) -> Bool {
        lhs === rhs
    }

    @inlinable
    static func areKnownEqual<V: Equatable>(_ lhs: borrowing V, _ rhs: borrowing V) -> Bool {
        lhs == rhs
    }

    @inlinable
    static func areKnownEqual<V: ReactiveObject & Equatable>(_ lhs: V, _ rhs: V) -> Bool {
        lhs === rhs
    }

    @inlinable
    static func areKnownEqual<V: __FunctionView>(_ lhs: borrowing V, _ rhs: borrowing V) -> Bool {
        V.__areEqual(a: lhs, b: rhs)
    }

    @inlinable
    static func areKnownEqual(_ lhs: borrowing String, _ rhs: borrowing String) -> Bool {
        lhs.utf8Equals(rhs)
    }
}
