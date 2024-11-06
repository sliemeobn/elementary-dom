@propertyWrapper
public struct State<V> {
    let initialValue: V
    var accessor: StateAccessor<V>?

    public var wrappedValue: V {
        get {
            guard let accessor else { return initialValue }
            return accessor.value
        }
        nonmutating set {
            guard let accessor else { fatalError("State.set called outside of content") }
            accessor.value = newValue
        }
        nonmutating _modify {
            guard let accessor else { fatalError("State._modify called outside of content") }
            yield &accessor.value
        }
    }

    public var projectedValue: Binding<V> {
        guard let accessor else { fatalError("State.projectedValue called outside of content") }
        return Binding(
            get: { accessor.value },
            set: { accessor.value = $0 }
        )
    }

    public init(wrappedValue: V) {
        initialValue = wrappedValue
    }
}

public extension State {
    mutating func __restoreState(storage: _ViewStateStorage, index: Int) {
        accessor = storage.accessor(for: index, as: V.self)
    }

    func __initializeState(storage: _ViewStateStorage, index: Int) {
        storage.initializeValueStorage(initialValue: initialValue, index: index)
    }
}

private extension _ViewStateStorage {
    func accessor<V>(for index: Int, as type: V.Type) -> StateAccessor<V> {
        StateAccessor(storage: self, index: index)
    }
}
