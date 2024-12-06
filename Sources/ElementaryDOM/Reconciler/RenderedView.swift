import Elementary

public struct _RenderedView {
    public enum Key: Equatable, Hashable {
        case structure(Int) // try to fold conditional chains and switches into this
        case explicit(String)

        static var falseKey: Self { .structure(0) }
        static var trueKey: Self { .structure(1) }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.structure(l), .structure(r)): return l == r
            case let (.explicit(l), .explicit(r)): return l.utf8Equals(r)
            default: return false
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case let .structure(index):
                hasher.combine(index)
            case let .explicit(key):
                // TODO: is this safe?
                key.withContiguousStorageIfAvailable { hasher.combine(bytes: UnsafeRawBufferPointer($0)) }
            }
        }
    }

    public enum Value {
        case nothing
        case text(String)
        case function(_RenderFunction)
        indirect case element(_DomElement, _RenderedView)
        indirect case lifecycle(_LifecycleHook, _RenderedView)
        indirect case keyed(Key, _RenderedView)
        case staticList([_RenderedView])
        case dynamicList([_RenderedView])
    }

    var value: Value

    public init(value: Value) {
        self.value = value
    }
}

public enum _LifecycleHook {
    case onMount(() -> Void)
    case onUnmount(() -> Void)
    case task(() async -> Void)
    case onMountReturningCancelFunction(() -> () -> Void)
    case __none
}

struct DOMEventListener {
    let event: String
    let handler: (AnyObject) -> Void
}

struct _DomEventListenerStorage {
    static var none: Self { _DomEventListenerStorage() }
    // TODO: fix typing
    var listeners: [DOMEventListener] = []

    // TODO: figure out how to a) do not use runtime reflection, b) do not drag JSKit dependency into app code, and c) provide extensible but typed event handling system
    func handleEvent(_ name: String, _ event: AnyObject) {
        for listener in listeners where listener.event.utf8Equals(name) {
            listener.handler(event)
        }
    }
}

public struct _DomElement {
    let tagName: String
    var attributes: _AttributeStorage
    var listerners: _DomEventListenerStorage
}
