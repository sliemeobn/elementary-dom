public extension ReactiveObject {
    static var environmentKey: EnvironmentValues._Key<Self> {
        EnvironmentValues._Key(_$typeID)
    }
}

public extension Environment {
    init(_: V.Type = V.self) where V: ReactiveObject {
        self.init(ObjectStorageReader(V.self))
    }

    init<O: ReactiveObject>(_: V.Type = V.self) where V == O? {
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
