protocol DOMElementModifier: AnyObject {
    associatedtype Value

    static var key: DOMElementModifiers.Key<Self> { get }

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _TransactionContext)
    func updateValue(_ value: consuming Value, _ context: inout _TransactionContext)

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable
}

protocol Unmountable: AnyObject {
    func unmount(_ context: inout _CommitContext)
}

extension DOMElementModifier {
    static var key: DOMElementModifiers.Key<Self> {
        DOMElementModifiers.Key(Self.self)
    }
}

struct DOMElementModifiers {
    struct Key<Directive: DOMElementModifier> {
        let typeID: ObjectIdentifier

        init(_: Directive.Type) {
            typeID = ObjectIdentifier(Directive.self)
        }
    }

    private var storage: [ObjectIdentifier: any DOMElementModifier] = [:]

    var isEmpty: Bool {
        storage.isEmpty
    }

    subscript<Directive: DOMElementModifier>(_ key: Key<Directive>) -> Directive? {
        get {
            storage[key.typeID] as? Directive
        }
        set {
            if let newValue = newValue {
                storage[key.typeID] = newValue
            } else {
                storage.removeValue(forKey: key.typeID)
            }
        }
    }

    mutating func take() -> [any DOMElementModifier] {
        let directives = Array(storage.values)
        storage.removeAll(keepingCapacity: true)
        return directives
    }
}

struct AnyUnmountable {
    private let _unmount: (inout _CommitContext) -> Void

    init(_ unmountable: some Unmountable) {
        self._unmount = unmountable.unmount(_:)
    }

    func unmount(_ context: inout _CommitContext) {
        _unmount(&context)
    }
}

protocol Invalidateable {
    func invalidate(_ context: inout _TransactionContext)
}

struct AnyInvalidateable: Equatable {
    fileprivate let ref: ObjectIdentifier
    private let _invalidate: (inout _TransactionContext) -> Void

    init(_ invalidateable: some Invalidateable & AnyObject) {
        self.ref = ObjectIdentifier(invalidateable)
        self._invalidate = invalidateable.invalidate(_:)
    }

    func invalidate(_ context: inout _TransactionContext) {
        _invalidate(&context)
    }

    static func == (lhs: AnyInvalidateable, rhs: AnyInvalidateable) -> Bool {
        lhs.ref == rhs.ref
    }
}

struct DependencyTracker: ~Copyable {
    // NOTE: my best guess is that this will be very flat most of the time, so a dictionary is probably more wasteful
    private var dependencies: [AnyInvalidateable] = []

    var isEmpty: Bool {
        dependencies.isEmpty
    }

    mutating func addDependency(_ dependency: some Invalidateable & AnyObject) {
        dependencies.append(AnyInvalidateable(dependency))
    }

    mutating func removeDependency(_ dependency: some Invalidateable & AnyObject) {
        dependencies.removeAll { $0.ref == ObjectIdentifier(dependency) }
    }

    borrowing func invalidateAll(_ context: inout _TransactionContext) {
        for dependency in dependencies {
            dependency.invalidate(&context)
        }
    }
}
