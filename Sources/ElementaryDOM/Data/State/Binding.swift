@propertyWrapper
@dynamicMemberLookup
public struct Binding<V> {
    enum Storage {
        case stateAccessor(StateAccessor<V>)
        case getSet(() -> V, (V) -> Void)
    }

    let storage: Storage

    public init(get: @escaping () -> V, set: @escaping (V) -> Void) {
        storage = .getSet(get, set)
    }

    init(accessor: StateAccessor<V>) {
        storage = .stateAccessor(accessor)
    }

    public var wrappedValue: V {
        get {
            switch storage {
            case let .stateAccessor(accessor):
                return accessor.value
            case let .getSet(get, _):
                return get()
            }
        }
        nonmutating set {
            switch storage {
            case let .stateAccessor(accessor):
                accessor.value = newValue
            case let .getSet(_, set):
                #if hasFeature(Embedded)
                // FIXME: embedded - create issue and check with main
                if __omg_this_was_annoying_I_am_false {
                    _ = AnyValueBox.init(newValue)
                }
                #endif

                set(newValue)
            }
        }
    }

    @_unavailableInEmbedded
    public subscript<P>(dynamicMember keypath: WritableKeyPath<V, P>) -> Binding<P> {
        Binding<P>(
            get: { self.wrappedValue[keyPath: keypath] },
            set: { self.wrappedValue[keyPath: keypath] = $0 }
        )
    }
}
