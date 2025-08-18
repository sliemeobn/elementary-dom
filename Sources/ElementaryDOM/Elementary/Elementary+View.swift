import Elementary

// TODO: maybe this should not derive from HTML at all
// TODO: think about how the square MainActor-isolation with server side usage
// TODO: maybe the _renderView should "reconcile" itself directly into a generic reconciler type instread of returning a _RenderedView (possible saving some allocations/currency types)
public protocol View: HTML & _Mountable where Content: HTML & _Mountable {

    static func __applyContext(_ context: borrowing _ViewRenderingContext, to view: inout Self)
}

public protocol _Mountable {
    associatedtype Node: MountedNode

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node

    static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    )
}

public protocol _StatefulView: View {
    static func __initializeState(from view: borrowing Self) -> _ViewStateStorage
    static func __restoreState(_ storage: _ViewStateStorage, in view: inout Self)
}

public extension View where Content == Never {
    var content: Content {
        fatalError("This should never be called")
    }
}

extension Never: _Mountable {
    public typealias Node = EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        fatalError("This should never be called")
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {}
}

public struct _ViewRenderingContext {
    var eventListeners: _DomEventListenerStorage = .init()
    var attributes: _AttributeStorage = .none
    var environment: EnvironmentValues = .init()

    mutating func takeAttributes() -> _AttributeStorage {
        let attributes = self.attributes
        self.attributes = .none
        return attributes
    }

    mutating func takeListeners() -> _DomEventListenerStorage {
        let listeners = eventListeners
        eventListeners = .init()
        return listeners
    }

    public static var empty: Self {
        .init()
    }
}

extension HTMLElement: _Mountable, View where Content: _Mountable {
    public typealias Node = Element<Content.Node>

    private static func makeValue(_ view: borrowing Self, context: inout _ViewRenderingContext) -> _DomElement {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return _DomElement(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners()
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        Node(
            value: makeValue(view, context: &context),
            context: &reconciler,
            makeChild: { [context] r in Content._makeNode(view.content, context: context, reconciler: &r) }
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        let value = makeValue(view, context: &context)
        node.patch(
            value,
            context: &reconciler,
            patchChild: { [context] child, r in
                Content._patchNode(
                    view.content,
                    context: context,
                    node: &child,
                    reconciler: &r
                )
            }
        )
    }
}

extension HTMLVoidElement: _Mountable, View {
    public typealias Node = Element<EmptyNode>

    private static func makeValue(_ view: borrowing Self, context: inout _ViewRenderingContext) -> _DomElement {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return _DomElement(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners()
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        Node(
            value: makeValue(view, context: &context),
            context: &reconciler,
            makeChild: { _ in EmptyNode() }
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        let value = makeValue(view, context: &context)
        node.patch(
            value,
            context: &reconciler,
            patchChild: { child, r in
                // no children anyway
            }
        )
    }
}

extension HTMLText: _Mountable, View {
    public typealias Node = TextNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        Node(view.text, context: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        node.patch(view.text, context: &reconciler)
    }
}

extension EmptyHTML: _Mountable, View {
    public typealias Node = EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        EmptyNode()
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {}
}

extension Optional: View where Wrapped: View {}
extension Optional: _Mountable where Wrapped: _Mountable {
    public typealias Node = ConditionalNode<Wrapped.Node, EmptyNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        switch view {
        case let .some(view):
            return .init(a: Wrapped._makeNode(view, context: context, reconciler: &reconciler))
        case .none:
            return .init(b: EmptyNode())
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        switch view {
        case let .some(view):
            node.patchWithA(reconciler: &reconciler) { [context] a, r in
                if a == nil {
                    a = Wrapped._makeNode(view, context: context, reconciler: &r)
                } else {
                    Wrapped._patchNode(view, context: context, node: &a!, reconciler: &r)
                }
            }
        case .none:
            node.patchWithB(reconciler: &reconciler) { b, r in
                if b == nil {
                    b = EmptyNode()
                } else {
                }
            }
        }
    }
}

extension _HTMLConditional: View where TrueContent: View, FalseContent: View {}
extension _HTMLConditional: _Mountable where TrueContent: _Mountable, FalseContent: _Mountable {
    public typealias Node = ConditionalNode<TrueContent.Node, FalseContent.Node>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        switch view.value {
        case let .trueContent(content):
            return .init(a: TrueContent._makeNode(content, context: context, reconciler: &reconciler))
        case let .falseContent(content):
            return .init(b: FalseContent._makeNode(content, context: context, reconciler: &reconciler))
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        switch view.value {
        case let .trueContent(content):
            node.patchWithA(reconciler: &reconciler) { [context] a, r in
                if a == nil {
                    a = TrueContent._makeNode(content, context: context, reconciler: &r)
                } else {
                    TrueContent._patchNode(content, context: context, node: &a!, reconciler: &r)
                }
            }
        case let .falseContent(content):
            node.patchWithB(reconciler: &reconciler) { [context] b, r in
                if b == nil {
                    b = FalseContent._makeNode(content, context: context, reconciler: &r)
                } else {
                    FalseContent._patchNode(content, context: context, node: &b!, reconciler: &r)
                }
            }
        }
    }
}

extension _HTMLArray: _Mountable, View where Element: View {
    public typealias Node = Dynamic<Element.Node>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        Node(
            view.value.enumerated().map { [context] (index, element) in
                (
                    key: .structure(index),
                    node: Element._makeNode(element, context: context, reconciler: &reconciler)
                )
            },
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {

        // maybe we can optimize this
        let indexes = view.value.indices.map { _ViewKey.structure($0) }
        node.patch(
            indexes,
            context: &reconciler,
            makeOrPatchNode: { [context] index, node, r in
                if node == nil {
                    node = Element._makeNode(view.value[index], context: context, reconciler: &r)
                } else {
                    Element._patchNode(view.value[index], context: context, node: &node!, reconciler: &r)
                }
            }
        )

    }
}

extension ForEach: _Mountable, View where Content: _KeyReadableView, Data: Collection {
    public typealias Node = Dynamic<Content.Value.Node>

    public init<V: View>(
        _ data: Data,
        @HTMLBuilder content: @escaping @Sendable (Data.Element) -> V
    ) where Content == _KeyedView<V>, Data.Element: Identifiable, Data.Element.ID: LosslessStringConvertible {
        self.init(
            data,
            content: { _KeyedView(key: String($0.id), value: content($0)) }
        )
    }

    public init<ID: LosslessStringConvertible, V: View>(
        _ data: Data,
        key: @escaping @Sendable (Data.Element) -> ID,
        @HTMLBuilder content: @escaping @Sendable (Data.Element) -> V
    ) where Content == _KeyedView<V> {
        self.init(
            data,
            content: {
                _KeyedView(key: String(key($0)), value: content($0))
            }
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        Node(
            view._data
                .map { [context] value in
                    let view = view._contentBuilder(value)
                    return (key: view._key, node: Content.Value._makeNode(view._value, context: context, reconciler: &reconciler))
                },
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        let views = view._data.map { value in view._contentBuilder(value) }
        node.patch(
            views.map { $0._key },
            context: &reconciler
        ) { [context] index, node, r in
            if node == nil {
                node = Content.Value._makeNode(views[index]._value, context: context, reconciler: &r)
            } else {
                Content.Value._patchNode(views[index]._value, context: context, node: &node!, reconciler: &r)
            }
        }
    }
}

extension _AttributedElement: _Mountable, View where Content: _Mountable {
    public typealias Node = Content.Node

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        view.attributes.append(context.takeAttributes())
        context.attributes = view.attributes

        return Content._makeNode(view.content, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        view.attributes.append(context.takeAttributes())
        context.attributes = view.attributes

        Content._patchNode(
            view.content,
            context: context,
            node: &node,
            reconciler: &reconciler
        )
    }
}

public extension View {
    static func __applyContext(_ context: borrowing _ViewRenderingContext, to view: inout Self) {
        print("ERROR: Unsupported view type \(Self.self) encountered. Please make sure to use @View on all custom views.")
        fatalError("Unsuppored View type enountered. Please make sure to use @View on all custom views.")
    }
}
