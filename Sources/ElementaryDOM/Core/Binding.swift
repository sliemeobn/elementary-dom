@propertyWrapper
@dynamicMemberLookup
public struct Binding<V> {
    var get: () -> V
    var set: (V) -> Void

    public init(get: @escaping () -> V, set: @escaping (V) -> Void) {
        self.get = get
        self.set = set
    }

    public var wrappedValue: V {
        get { get() }
        nonmutating set { set(newValue) }
    }

    public subscript<P>(dynamicMember keypath: WritableKeyPath<V, P>) -> Binding<P> {
        Binding<P>(
            get: { self.wrappedValue[keyPath: keypath] },
            set: { self.wrappedValue[keyPath: keypath] = $0 }
        )
    }
}
