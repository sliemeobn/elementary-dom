import Elementary

public struct _RenderedView {
    public enum Value {
        case nothing
        case text(String)
        indirect case element(_DomElement, _RenderedView)
        case function(_RenderFunction)
        case list([_RenderedView]) // think about if we can get rid of this and handle lists/tuples differently
    }

    var value: Value

    public init(value: Value) {
        self.value = value
    }
}

struct EventListener {
    let event: String
    let handler: (AnyObject) -> Void
}

struct _DomEventListenerStorage {
    static var none: Self { _DomEventListenerStorage() }
    // TODO: fix typing
    var listeners: [EventListener] = []

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

// trying to stay embedded swift compatible eventually
public typealias _ManagedState = _ViewStateStorage

// TODO: better name
public struct _RenderFunction {
    // TODO: think about equality checking or short-circuiting unchanged stuff
    var initializeState: (() -> _ManagedState)?
    var getContent: (_ state: _ManagedState?) -> _RenderedView

    public init(initializeState: (() -> _ManagedState)?, getContent: @escaping (_ state: _ManagedState?) -> _RenderedView) {
        self.initializeState = initializeState
        self.getContent = getContent
    }
}

extension _RenderFunction {
    static func from<V: View>(_ view: consuming sending V, context: _ViewRenderingContext) -> _RenderFunction {
        // TODO: maybe re-setting state-storage should be done outside of this via thread-locals or just a global thing something?
        // captures context and content's render function
        .init(
            initializeState: nil,
            getContent: { [view] _ in V.Content._renderView(view.content, context: context) }
        )
    }
}
