public protocol DOMEventHandlerConfig {
    static var name: String { get }
    associatedtype Event: DOMEvent
}

final class EventModifier<Config: DOMEventHandlerConfig>: DOMElementModifier {
    typealias Value = (Config.Event) -> Void

    let upstream: EventModifier?
    var tracker: DependencyTracker = .init()

    private var value: Value

    init(value: consuming @escaping Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.value = value
        self.upstream = upstream[EventModifier.key]
    }

    func updateValue(_ value: consuming @escaping Value, _ context: inout _RenderContext) {
        self.value = value
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        logTrace("mounting event modifier")
        return AnyUnmountable(MountedInstance(node, self, &context))
    }

    func handleEvent(_ name: String, event: DOM.Event) {
        assert(name.utf8Equals(Config.name), "Unexpected event name for \(Config.name)")
        guard let event = Config.Event(raw: event) else {
            logWarning("Unexpected event type for \(Config.name)")
            return
        }

        value(event)
        upstream?.value(event)
    }
}

extension EventModifier {
    final class MountedInstance: Unmountable {
        let modifier: EventModifier
        let node: DOM.Node
        var sink: DOM.EventSink?

        var isDirty: Bool = false

        init(_ node: DOM.Node, _ modifier: EventModifier, _ context: inout _CommitContext) {
            self.node = node
            self.modifier = modifier

            let sink = context.dom.makeEventSink { [modifier] name, event in
                modifier.handleEvent(name, event: event)
            }

            context.dom.addEventListener(node, event: Config.name, sink: sink)
            self.sink = sink
        }

        func unmount(_ context: inout _CommitContext) {
            guard let sink = self.sink else {
                return
            }

            context.dom.removeEventListener(node, event: Config.name, sink: sink)
            self.sink = nil
        }
    }
}
