import Elementary

public struct _RenderedView {
    public enum Value {
        case nothing
        case text(String)
        indirect case element(_DomElement, _RenderedView)
        indirect case lifecycle(_LifecycleHook, _RenderedView)
        case function(_RenderFunction)
        case list([_RenderedView]) // think about if we can get rid of this and handle lists/tuples differently
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
