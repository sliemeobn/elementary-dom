@propertyWrapper
public struct Environment<V> {
    enum Storage {
        case value(V)
        case valueBox(EnvironmentValues._Box<V>)
        case valueKey(EnvironmentValues._Key<V>)
        case objectReader(ObjectStorageReader<V>, AnyObject?)
    }

    var storage: Storage

    public init(_ accessor: EnvironmentValues._Key<V>) {
        storage = .valueKey(accessor)
    }

    init(_ objectReader: ObjectStorageReader<V>) {
        storage = .objectReader(objectReader, nil)
    }

    public var wrappedValue: V {
        switch storage {
        case let .value(value):
            value
        case let .valueBox(box):
            box.value
        case let .valueKey(accessor):
            accessor.defaultValue
        case let .objectReader(reader, box):
            reader.read(box)
        }
    }

    public mutating func __load(from context: borrowing _ViewContext) {
        __load(from: context.environment)
    }

    mutating func __load(from values: borrowing EnvironmentValues) {
        switch storage {
        case let .valueKey(key):
            if let box = values.boxes[key.propertyID] {
                storage = .valueBox(box as! EnvironmentValues._Box<V>)
            } else {
                storage = .value(key.defaultValue)
            }
        case let .objectReader(reader, _):
            storage = .objectReader(reader, values.boxes[reader.propertyID])
        default:
            fatalError("Cannot load environment value twice")
        }
    }
}

public struct EnvironmentValues: _ValueStorage {
    var boxes: [PropertyID: AnyObject] = [:]

    public subscript<Value>(key: _Key<Value>) -> Value {
        get {
            (boxes[key.propertyID] as? _Box<Value>)?.value ?? key.defaultValue
        }
        set {
            boxes[key.propertyID] = _Box<Value>(newValue)
        }
    }
}

extension EnvironmentValues {
    public final class _Box<Value> {
        let _value_id = PropertyID(0)
        var _registrar = ReactivityRegistrar()

        var _value: Value

        var value: Value {
            get {
                _registrar.access(_value_id)
                return _value
            }
            set {
                _registrar.willSet(_value_id)
                _value = newValue
                _registrar.didSet(_value_id)
            }
            _modify {
                _registrar.access(_value_id)
                _registrar.willSet(_value_id)
                defer { _registrar.didSet(_value_id) }
                yield &_value
            }
        }

        init(_ value: Value) {
            self._value = value
        }
    }
}
