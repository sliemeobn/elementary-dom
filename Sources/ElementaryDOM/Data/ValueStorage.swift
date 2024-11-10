public protocol _ValueStorage {
    typealias _Key<Value> = _StorageKey<Self, Value>
    // TODO: get rid of this public thing
    subscript<Value>(key: _Key<Value>) -> Value { get set }
}

public struct _StorageKey<Storage: _ValueStorage, Value>: Sendable {
    private let defaultValueClosure: (@Sendable () -> sending Value)?
    public let propertyID: PropertyID

    public var defaultValue: Value {
        if let closure = defaultValueClosure {
            return closure()
        } else {
            print("ERROR: Unavailable default value accessed for \(Value.self) with property ID \(propertyID)")
            fatalError("Unavailable default value accessed")
        }
    }

    public init(_ propertyID: PropertyID, defaultValue: @autoclosure @Sendable @escaping () -> sending Value) {
        self.propertyID = propertyID
        defaultValueClosure = defaultValue
    }

    init(_ propertyID: PropertyID) {
        self.propertyID = propertyID
        defaultValueClosure = nil
    }
}
