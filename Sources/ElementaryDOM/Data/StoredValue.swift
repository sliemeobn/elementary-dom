
struct StoredValue {
    private enum Kind {
        case boxedValue
    }

    private final class Box<V> {
        var value: V

        init(_ value: V) {
            self.value = value
        }
    }

    private var storage: AnyObject
    private var kind: Kind

    init<T>(_ value: T) {
        storage = Box(value)
        kind = .boxedValue
    }

    // init<T: AnyObject>(_ value: T) {
    //     storage = value
    //     kind = .object
    // }

    subscript<T>(as type: T.Type = T.self) -> T {
        get {
            switch kind {
            case .boxedValue:
                return (storage as! Box<T>).value
            }
        }
        set {
            switch kind {
            case .boxedValue:
                (storage as! Box<T>).value = newValue
            }
        }
        _modify {
            switch kind {
            case .boxedValue:
                yield &((storage as! Box<T>).value)
            }
        }
    }
}
