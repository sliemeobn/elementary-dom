import Elementary

public enum _LifecycleHook {
    case onMount(() -> Void)
    case onUnmount(() -> Void)
    case onMountReturningCancelFunction(() -> () -> Void)
    case __none
}

struct DOMEventListener {
    let event: String
    let handler: (DOM.Event) -> Void
}

struct _DomEventListenerStorage {
    static var none: Self { _DomEventListenerStorage() }
    // TODO: fix typing
    var listeners: [DOMEventListener] = []

    // TODO: figure out how to a) do not use runtime reflection, b) do not drag JSKit dependency into app code, and c) provide extensible but typed event handling system
    func handleEvent(_ name: String, _ event: DOM.Event) {
        for listener in listeners where listener.event.utf8Equals(name) {
            listener.handler(event)
        }
    }
}

public struct _DomTranstionHooks {

}
