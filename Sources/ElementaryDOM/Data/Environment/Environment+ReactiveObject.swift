public extension ReactiveObject {
    static var environmentKey: EnvironmentValues._Key<Self> {
        EnvironmentValues._Key(_$typeID)
    }
}

public extension Environment {
    init(_: V.Type = V.self) where V: ReactiveObject {
        self.init(ObjectStorageReader(V.self))
    }

    // NOTE: in embedded for some reason this causes a compiler crash around the (actually unused) StoredValue<Optional<O>> type
    // ¯\_(ツ)_/¯ - try again with a newer toolchain in the future
    @_unavailableInEmbedded
    init<O: ReactiveObject>(_: O.Type = O.self) where V == O? {
        self.init(ObjectStorageReader(V.self))
    }
}

struct ObjectStorageReader<Value> {
    let read: (borrowing [PropertyID: StoredValue]) -> Value

    init(_: Value.Type) where Value: ReactiveObject {
        let propertyID = Value.environmentKey.propertyID
        read = {
            if let value = $0[propertyID] {
                return value[as: Value.self]
            } else {
                fatalError()
            }
        }
    }

    init<O: ReactiveObject>(_: Value.Type) where Value == O? {
        let propertyID = O.environmentKey.propertyID
        read = { $0[propertyID]?[as: O.self] }
    }
}
