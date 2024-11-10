import Reactivity

@Reactive
public final class _ViewStateStorage {
    // TODO: maybe we can store AnyObjects directly instread of double-boxing them
    @ReactiveIgnored
    private var values: [StoredValue] = []

    public init() {}

    public func reserveCapacity(_ capacity: Int) {
        values.reserveCapacity(capacity)
    }

    public func initializeValueStorage<V>(initialValue: V, index: Int) {
        precondition(index == values.count, "State storage must be initialized in order")
        values.append(StoredValue(initialValue))
    }

    public func initializeValueStorage<V: AnyObject>(initialValue: V, index: Int) {
        precondition(index == values.count, "State storage must be initialized in order")
        values.append(StoredValue(initialValue))
    }

    public subscript<V>(_ index: Int, as type: V.Type = V.self) -> V {
        get {
            _$reactivity.access(PropertyID(index))
            return values[index][]
        }
        set {
            _$reactivity.willSet(PropertyID(index))
            values[index][] = newValue
            _$reactivity.didSet(PropertyID(index))
        }
        _modify {
            _$reactivity.access(PropertyID(index))
            _$reactivity.willSet(PropertyID(index))
            yield &values[index][]
            _$reactivity.didSet(PropertyID(index))
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
