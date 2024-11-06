import Reactivity

public final class _ViewStateStorage: ReactiveObject {
    final class Box<V> {
        var value: V

        init(_ value: V) {
            self.value = value
        }
    }

    // TODO: maybe we can store AnyObjects directly instread of double-boxing them
    private var reactivityRegistrar: ReactivityRegistrar = .init()
    private var values: [AnyObject] = []

    public init() {}

    public func reserveCapacity(_ capacity: Int) {
        values.reserveCapacity(capacity)
    }

    public func initializeValueStorage<V>(initialValue: V, index: Int) {
        precondition(index == values.count, "State storage must be initialized in order")
        values.append(Box(initialValue))
    }

    public subscript<V>(_ index: Int, as type: V.Type = V.self) -> V {
        get {
            reactivityRegistrar.access(PropertyID(index))
            return (values[index] as! Box<V>).value
        }
        set {
            reactivityRegistrar.willSet(PropertyID(index))
            (values[index] as! Box<V>).value = newValue
            reactivityRegistrar.didSet(PropertyID(index))
        }
        _modify {
            reactivityRegistrar.access(PropertyID(index))
            reactivityRegistrar.willSet(PropertyID(index))
            yield &((values[index] as! Box<V>).value)
            reactivityRegistrar.didSet(PropertyID(index))
        }
    }
}

struct StateAccessor<V> {
    let storage: _ViewStateStorage
    let index: Int

    var value: V {
        get {
            storage[index]
        }
        nonmutating set {
            storage[index] = newValue
        }
        nonmutating _modify {
            yield &storage[index]
        }
    }
}
