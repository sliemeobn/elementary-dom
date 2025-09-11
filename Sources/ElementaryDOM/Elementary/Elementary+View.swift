import Elementary

// TODO: maybe this should not derive from HTML at all, or maybe HTML should already be "View" and _Mountable is an extra requirement for mounting?
// TODO: think about how the square MainActor-isolation with server side usage
public protocol View: HTML & _Mountable where Content: HTML & _Mountable {
}

public protocol _Mountable {
    associatedtype _MountedNode: _Reconcilable

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode

    static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    )
}

public extension View where Content == Never {
    var content: Content {
        fatalError("This should never be called")
    }
}

extension Never: _Mountable {
    public typealias _MountedNode = _EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        fatalError("This should never be called")
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

// TODO: does this need to be extra?
public struct _ViewContext {
    // TODO: get red of this
    var eventListeners: _DomEventListenerStorage = .init()
    // TODO: get red of this
    var attributes: _AttributeStorage = .none

    var environment: EnvironmentValues = .init()
    var directives: DOMElementModifiers = .init()

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

    mutating func takeDirectives() -> [any DOMElementModifier] {
        directives.takeModifiers()
    }

    public static var empty: Self {
        .init()
    }
}

extension HTMLElement: _Mountable, View where Content: _Mountable {
    public typealias _MountedNode = _ElementNode<Content._MountedNode>

    private static func makeValue(_ view: borrowing Self, context: inout _ViewContext) -> _MountedNode.Value {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return .init(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners(),
            modifiers: context.takeDirectives()
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            value: makeValue(view, context: &context),
            context: &reconciler,
            makeChild: { [context] r in Content._makeNode(view.content, context: context, reconciler: &r) }
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
    public typealias _MountedNode = _ElementNode<_EmptyNode>

    private static func makeValue(_ view: borrowing Self, context: inout _ViewContext) -> _MountedNode.Value {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return .init(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners(),
            modifiers: context.takeDirectives()
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            value: makeValue(view, context: &context),
            context: &reconciler,
            makeChild: { _ in _EmptyNode() }
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
    public typealias _MountedNode = _TextNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(view.text, context: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(view.text, context: &reconciler)
    }
}

extension EmptyHTML: _Mountable, View {
    public typealias _MountedNode = _EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _EmptyNode()
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

extension Optional: View where Wrapped: View {}
extension Optional: _Mountable where Wrapped: _Mountable {
    public typealias _MountedNode = _ConditionalNode<Wrapped._MountedNode, _EmptyNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view {
        case let .some(view):
            return .init(a: Wrapped._makeNode(view, context: context, reconciler: &reconciler))
        case .none:
            return .init(b: _EmptyNode())
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
                    b = _EmptyNode()
                } else {
                }
            }
        }
    }
}

extension _HTMLConditional: View where TrueContent: View, FalseContent: View {}
extension _HTMLConditional: _Mountable where TrueContent: _Mountable, FalseContent: _Mountable {
    public typealias _MountedNode = _ConditionalNode<TrueContent._MountedNode, FalseContent._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view.value {
        case let .trueContent(content):
            return .init(a: TrueContent._makeNode(content, context: context, reconciler: &reconciler))
        case let .falseContent(content):
            return .init(b: FalseContent._makeNode(content, context: context, reconciler: &reconciler))
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
    public typealias _MountedNode = _KeyedNode<Element._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            view.value.enumerated().map { [context] (index, element) in
                (
                    key: _ViewKey(String(index)),
                    node: Element._makeNode(element, context: context, reconciler: &reconciler)
                )
            },
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        // maybe we can optimize this
        // NOTE: written with cast for this https://github.com/swiftlang/swift/issues/83895
        let indexes = view.value.indices.map { _ViewKey(String($0 as Int)) }

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
    public typealias _MountedNode = _KeyedNode<Content.Value._MountedNode>

    public init<V: View>(
        _ data: Data,
        @HTMLBuilder content: @escaping @Sendable (Data.Element) -> V
    ) where Content == _KeyedView<V>, Data.Element: Identifiable, Data.Element.ID: LosslessStringConvertible {
        self.init(
            data,
            content: { _KeyedView(key: _ViewKey($0.id), value: content($0)) }
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
                _KeyedView(key: _ViewKey(key($0)), value: content($0))
            }
        )
    }

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
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
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
    public typealias _MountedNode = Content._MountedNode

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        view.attributes.append(context.takeAttributes())
        context.attributes = view.attributes

        return Content._makeNode(view.content, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
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
    static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self) {
        print("ERROR: Unsupported view type \(Self.self) encountered. Please make sure to use @View on all custom views.")
        fatalError("Unsuppored View type enountered. Please make sure to use @View on all custom views.")
    }
}
