import Elementary

// TODO: maybe this should not derive from HTML at all, or maybe HTML should already be "View" and _Mountable is an extra requirement for mounting?
// TODO: think about how the square MainActor-isolation with server side usage
public protocol View<Tag>: HTML & _Mountable where Content: HTML & _Mountable {
}

public protocol _Mountable {
    associatedtype _MountedNode: _Reconcilable

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode

    static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
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
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        fatalError("This should never be called")
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

public struct _ViewContext {
    var environment: EnvironmentValues = .init()

    // built-in typed environment values (maybe using plain-old keys might be better?)
    var modifiers: DOMElementModifiers = .init()
    var functionDepth: Int = 0
    var parentElement: _ElementNode?

    mutating func takeModifiers() -> [any DOMElementModifier] {
        modifiers.takeModifiers()
    }

    public static var empty: Self {
        .init()
    }
}

extension HTMLElement: _Mountable, View where Content: _Mountable {
    public typealias _MountedNode = _StatefulNode<_AttributeModifier, _ElementNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let attributeModifier = _AttributeModifier(value: view._attributes, upstream: context.modifiers, &reconciler)

        var context = copy context
        context.modifiers[_AttributeModifier.key] = attributeModifier

        return _MountedNode(
            state: attributeModifier,
            child: _ElementNode(
                tag: self.Tag.name,
                viewContext: context,
                context: &reconciler,
                makeChild: { viewContext, r in AnyReconcilable(Content._makeNode(view.content, context: viewContext, reconciler: &r)) }
            )
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view._attributes, &reconciler)

        node.child.updateChild(&reconciler, as: Content._MountedNode.self) { child, r in
            Content._patchNode(
                view.content,
                node: child,
                reconciler: &r
            )
        }
    }
}

extension HTMLVoidElement: _Mountable, View {
    public typealias _MountedNode = _StatefulNode<_AttributeModifier, _ElementNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let attributeModifier = _AttributeModifier(value: view._attributes, upstream: context.modifiers, &reconciler)

        var context = copy context
        context.modifiers[_AttributeModifier.key] = attributeModifier

        return _MountedNode(
            state: attributeModifier,
            child: _ElementNode(
                tag: self.Tag.name,
                viewContext: context,
                context: &reconciler,
                makeChild: { _, _ in AnyReconcilable(_EmptyNode()) }
            )
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view._attributes, &reconciler)
    }
}

extension HTMLText: _Mountable, View {
    public typealias _MountedNode = _TextNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(view.text, viewContext: context, context: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(view.text, context: &reconciler)
    }
}

extension EmptyHTML: _Mountable, View {
    public typealias _MountedNode = _EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _EmptyNode()
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

extension Optional: View where Wrapped: View {}
extension Optional: _Mountable where Wrapped: _Mountable {
    public typealias _MountedNode = _ConditionalNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view {
        case let .some(view):
            return .init(a: Wrapped._makeNode(view, context: context, reconciler: &reconciler), context: context)
        case .none:
            return .init(b: _EmptyNode(), context: context)
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        switch view {
        case let .some(view):
            node.patchWithA(
                reconciler: &reconciler,
                makeNode: { c, r in Wrapped._makeNode(view, context: c, reconciler: &r) },
                updateNode: { node, r in Wrapped._patchNode(view, node: node, reconciler: &r) }
            )
        case .none:
            node.patchWithB(
                reconciler: &reconciler,
                makeNode: { _, _ in _EmptyNode() },
                updateNode: { _, _ in }
            )
        }
    }
}

extension _HTMLConditional: View where TrueContent: View, FalseContent: View {}
extension _HTMLConditional: _Mountable where TrueContent: _Mountable, FalseContent: _Mountable {
    public typealias _MountedNode = _ConditionalNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        switch view.value {
        case let .trueContent(content):
            return .init(a: TrueContent._makeNode(content, context: context, reconciler: &reconciler), context: context)
        case let .falseContent(content):
            return .init(b: FalseContent._makeNode(content, context: context, reconciler: &reconciler), context: context)
        }
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        switch view.value {
        case let .trueContent(content):
            node.patchWithA(
                reconciler: &reconciler,
                makeNode: { c, r in TrueContent._makeNode(content, context: c, reconciler: &r) },
                updateNode: { node, r in TrueContent._patchNode(content, node: node, reconciler: &r) }
            )
        case let .falseContent(content):
            node.patchWithB(
                reconciler: &reconciler,
                makeNode: { c, r in FalseContent._makeNode(content, context: c, reconciler: &r) },
                updateNode: { node, r in FalseContent._patchNode(content, node: node, reconciler: &r) }
            )
        }
    }
}

extension _HTMLArray: _Mountable, View where Element: View {
    public typealias _MountedNode = _KeyedNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            view.value.enumerated().map { (index, element) in
                (
                    key: _ViewKey(String(index)),
                    node: Element._makeNode(element, context: context, reconciler: &reconciler)
                )
            },
            context: context
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        // maybe we can optimize this
        // NOTE: written with cast for this https://github.com/swiftlang/swift/issues/83895
        let indexes = view.value.indices.map { _ViewKey(String($0 as Int)) }

        node.patch(
            indexes,
            context: &reconciler,
            as: Element._MountedNode.self,
            makeOrPatchNode: { index, node, context, r in
                if node == nil {
                    node = Element._makeNode(view.value[index], context: context, reconciler: &r)
                } else {
                    Element._patchNode(view.value[index], node: node!, reconciler: &r)
                }
            }
        )

    }
}

extension ForEach: _Mountable, View where Content: _KeyReadableView, Data: Collection {
    public typealias _MountedNode = _KeyedNode

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
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        _MountedNode(
            view._data
                .map { value in
                    let view = view._contentBuilder(value)
                    return (key: view._key, node: Content.Value._makeNode(view._value, context: context, reconciler: &reconciler))
                },
            context: context
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        let views = view._data.map { value in view._contentBuilder(value) }
        node.patch(
            views.map { $0._key },
            context: &reconciler,
            as: Content.Value._MountedNode.self,
        ) { index, node, context, r in
            if node == nil {
                node = Content.Value._makeNode(views[index]._value, context: context, reconciler: &r)
            } else {
                Content.Value._patchNode(views[index]._value, node: node!, reconciler: &r)
            }
        }
    }
}

extension _AttributedElement: _Mountable, View where Content: _Mountable {
    public typealias _MountedNode = _StatefulNode<_AttributeModifier, Content._MountedNode>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let attributeModifier = _AttributeModifier(value: view.attributes, upstream: context.modifiers, &reconciler)

        var context = copy context
        context.modifiers[_AttributeModifier.key] = attributeModifier

        return _MountedNode(
            state: attributeModifier,
            child: Content._makeNode(view.content, context: context, reconciler: &reconciler)
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view.attributes, &reconciler)

        Content._patchNode(
            view.content,
            node: node.child,
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
