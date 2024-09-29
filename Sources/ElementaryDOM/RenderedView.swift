import Elementary

public struct _RenderedView {
    enum Value {
        case nothing
        case text(String)
        indirect case element(DomElement, _RenderedView)
        case function(RenderFunction)
        case list([_RenderedView]) // think about if we can get rid of this and handle lists/tuples differently
    }

    var value: Value
}

struct _DomEventListenerStorage {
    static var none: Self { _DomEventListenerStorage() }
    // TODO: fix typing
    var listeners: [EventHandler] = []

    // TODO: figure out how to a) do not use runtime reflection, b) do not drag JSKit dependency into app code, and c) provide extensible but typed event handling system
    @MainActor
    func handleEvent(_ name: String, _ event: AnyObject) {
        for listener in listeners where listener.event == name {
            listener.handler(event)
        }
    }
}

struct DomElement {
    let tagName: String
    var attributes: _AttributeStorage
    var listerners: _DomEventListenerStorage
}

// trying to stay embedded swift compatible eventually
typealias ManagedState = AnyObject

// TODO: better name
@MainActor
struct RenderFunction {
    // TODO: think about equality checking or short-circuiting unchanged stuff
    var createInitialState: (() -> ManagedState)?
    var getContent: @MainActor (_ state: ManagedState?) -> _RenderedView
}

extension RenderFunction {
    @MainActor
    static func from<V: View>(_ view: consuming sending V, context: _ViewRenderingContext) -> RenderFunction {
        // TODO: maybe re-setting state-storage should be done outside of this via thread-locals or just a global thing something?
        // captures context and content's render function
        .init(
            createInitialState: nil,
            getContent: { [view] _ in V.Content._renderView(view.content, context: context) }
        )
    }
}
