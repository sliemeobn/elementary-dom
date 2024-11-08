@propertyWrapper
public struct Environment<V> {
    enum Storage {
        case value(V)
        case accessor(_StorageKey<EnvironmentValues, V>)
    }

    var storage: Storage

    public init(_ accessor: _StorageKey<EnvironmentValues, V>) {
        storage = .accessor(accessor)
    }

    public var wrappedValue: V {
        switch storage {
        case let .value(value):
            return value
        case let .accessor(accessor):
            return accessor.defaultValue()
        }
    }

    public mutating func __load(from context: _ViewRenderingContext) {
        __load(from: context.environment)
    }

    mutating func __load(from values: borrowing EnvironmentValues) {
        switch storage {
        case let .accessor(accessor):
            storage = .value(values[accessor])
        default:
            fatalError("Cannot load environment value twice")
        }
    }
}

extension EnvironmentValues: _ValueStorage {
    public subscript<Value>(key: _StorageKey<EnvironmentValues, Value>) -> Value {
        get {
            if let value = values[key.propertyID] {
                return value[]
            } else {
                return key.defaultValue()
            }
        }
        set {
            values[key.propertyID] = StoredValue(newValue)
        }
    }
}

public protocol _ValueStorage {
    typealias _Key<Value> = _StorageKey<Self, Value>
    subscript<Value>(key: _Key<Value>) -> Value { get set }
}

public struct _StorageKey<Storage: _ValueStorage, Value>: Sendable {
    let propertyID: PropertyID
    let defaultValue: @Sendable () -> sending Value

    public init(_ propertyID: PropertyID, defaultValue: @autoclosure @Sendable @escaping () -> sending Value) {
        self.propertyID = propertyID
        self.defaultValue = defaultValue
    }
}

public struct EnvironmentValues {
    var values: [PropertyID: StoredValue] = [:]
}
