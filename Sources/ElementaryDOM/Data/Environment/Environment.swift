@propertyWrapper
public struct Environment<V> {
    enum Storage {
        case value(V)
        case valueKey(EnvironmentValues._Key<V>)
        case objectReader(ObjectStorageReader<V>)
    }

    var storage: Storage

    public init(_ accessor: EnvironmentValues._Key<V>) {
        storage = .valueKey(accessor)
    }

    init(_ objectReader: ObjectStorageReader<V>) {
        storage = .objectReader(objectReader)
    }

    public var wrappedValue: V {
        switch storage {
        case let .value(value):
            value
        case let .valueKey(accessor):
            accessor.defaultValue
        case let .objectReader(reader):
            reader.read([:])
        }
    }

    public mutating func __load(from context: borrowing _ViewRenderingContext) {
        __load(from: context.environment)
    }

    mutating func __load(from values: borrowing EnvironmentValues) {
        switch storage {
        case let .valueKey(key):
            storage = .value(values[key])
        case let .objectReader(reader):
            storage = .value(reader.read(values.values))
        default:
            fatalError("Cannot load environment value twice")
        }
    }
}

public struct EnvironmentValues: _ValueStorage {
    var values: [PropertyID: StoredValue] = [:]

    public subscript<Value>(key: _Key<Value>) -> Value {
        get {
            values[key.propertyID]?[as: Value.self] ?? key.defaultValue
        }
        set {
            values[key.propertyID] = StoredValue(newValue)
        }
    }
}
