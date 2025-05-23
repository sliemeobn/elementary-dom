struct StoredValue {
    private final class Box<V> {
        var value: V

        init(_ value: V) {
            self.value = value
        }
    }

    private var storage: AnyObject

    init<T>(_ value: T) {
        storage = Box(value)
    }

    subscript<T>(as type: T.Type = T.self) -> T {
        get {
            (storage as! Box<T>).value
        }
        set {
            (storage as! Box<T>).value = newValue
        }
        _modify {
            yield &((storage as! Box<T>).value)
        }
    }
}
