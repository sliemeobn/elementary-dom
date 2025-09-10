import JavaScriptKit
import Reactivity

struct DOMElementDirectives {
    struct Key<Directive: DOMElementDirective> {
        let typeID: ObjectIdentifier

        init(_: Directive.Type) {
            typeID = ObjectIdentifier(Directive.self)
        }
    }

    private var storage: [ObjectIdentifier: AnyDOMDirective] = [:]

    subscript<Directive: DOMElementDirective>(_ key: Key<Directive>) -> Directive? {
        get {
            storage[key.typeID]?.ref as? Directive
        }
        set {
            if let newValue = newValue {
                storage[key.typeID] = AnyDOMDirective(newValue)
            } else {
                storage.removeValue(forKey: key.typeID)
            }
        }
    }

    consuming func takeDirectives() -> [AnyDOMDirective] {
        let directives = Array(storage.values)
        storage.removeAll()
        return directives
    }
}

struct AnyDOMDirective {
    fileprivate let ref: AnyObject
    private let _mount: (DOM.Node, inout _CommitContext) -> AnyMountedDOMDirective

    init<Directive: DOMElementDirective>(_ directive: Directive) {
        self.ref = directive
        self._mount = { node, context in
            AnyMountedDOMDirective(directive.mount(node, &context))
        }
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyMountedDOMDirective {
        _mount(node, &context)
    }
}

struct AnyMountedDOMDirective {
    private let _unmount: (DOM.Node, inout _CommitContext) -> Void

    init<Mounted: MountedDOMNodeDirective>(_ directive: Mounted) {
        self._unmount = directive.unmount(_:_:)
    }

    func unmount(_ node: DOM.Node, _ context: inout _CommitContext) {
        _unmount(node, &context)
    }
}

final class TextBindingDirective: DOMElementDirective, MountedDOMNodeDirective {
    typealias Value = Binding<String>
    private var lastValue: String
    var binding: Value

    var mountedNode: DOM.Node?
    var sink: DOM.EventSink?
    var accessor: DOM.PropertyAccessor?
    var isDirty: Bool = false

    init(value: consuming Value, upstream: TextBindingDirective?, _ context: inout _RenderContext) {
        self.binding = value
        self.lastValue = value.wrappedValue
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        self.binding = value

        if !binding.wrappedValue.utf8Equals(lastValue) {
            self.lastValue = binding.wrappedValue
            markDirty(&context)
        }
    }

    private func markDirty(_ context: inout _RenderContext) {
        guard !isDirty else { return }
        isDirty = true

        context.commitPlan.addNodeAction(
            CommitAction(run: updateDOMNode)
        )
    }

    private func updateDOMNode(_ context: inout _CommitContext) {
        guard let accessor = self.accessor else { return }
        accessor.set(.string(lastValue))
        isDirty = false
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> some MountedDOMNodeDirective {
        if mountedNode != nil {
            assertionFailure("Binding effect can only be mounted on a single element")
            self.unmount(mountedNode!, &context)
        }

        self.mountedNode = node
        let accessor = context.dom.makePropertyAccessor(node, name: "value")
        self.accessor = accessor

        let sink = context.dom.makeEventSink { [self] name, event in
            guard let value = self.accessor?.get() else {
                logWarning("Unexpected property value read from accessor")
                return
            }

            switch value {
            case let .string(value):
                self.lastValue = value
                self.binding.wrappedValue = value
            default:
                // TODO: think about what to do....
                logWarning("Unexpected property value read from accessor")
            }
        }

        context.dom.addEventListener(node, event: "input", sink: sink)
        return self
    }

    func unmount(_ node: DOM.Node, _ context: inout _CommitContext) {
        guard let sink = self.sink, let node = self.mountedNode else {
            assertionFailure("Binding effect can only be unmounted on a mounted element")
            return
        }

        context.dom.removeEventListener(node, event: "input", sink: sink)
        self.mountedNode = nil
        self.sink = nil
    }
}

// protocol BindingConfiguration {
//     associatedtype Value
//     static var propertyName: String { get }
//     static var eventName: String { get }
//     static func readValue(_ jsValue: DOM.PropertyValue) -> Value?
//     static func writeValue(_ value: Value) -> DOM.PropertyValue
// }

struct DependencyList: ~Copyable {
    private var downstreams: [() -> Void] = []

    mutating func add(_ invalidate: @escaping () -> Void) {
        downstreams.append(invalidate)
    }

    func invalidateAll() {
        for downstream in downstreams {
            downstream()
        }
    }
}

protocol DOMElementDirective: AnyObject {
    associatedtype Value
    associatedtype MountedDirective: MountedDOMNodeDirective

    static var key: DOMElementDirectives.Key<Self> { get }

    init(value: consuming Value, upstream: Self?, _ context: inout _RenderContext)
    func updateValue(_ value: consuming Value, _ context: inout _RenderContext)

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> MountedDirective
}

extension DOMElementDirective {
    static var key: DOMElementDirectives.Key<Self> {
        DOMElementDirectives.Key(Self.self)
    }
}

protocol MountedDOMNodeDirective: AnyObject {
    func unmount(_ node: DOM.Node, _ context: inout _CommitContext)
}
