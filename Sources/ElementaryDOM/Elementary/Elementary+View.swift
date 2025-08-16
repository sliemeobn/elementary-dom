import Elementary

// TODO: maybe this should not derive from HTML at all
// TODO: think about how the square MainActor-isolation with server side usage
// TODO: maybe the _renderView should "reconcile" itself directly into a generic reconciler type instread of returning a _RenderedView (possible saving some allocations/currency types)
public protocol View: HTML where Content: View {
    static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView
    static func __applyContext(_ context: borrowing _ViewRenderingContext, to view: inout Self)

    static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM>

    static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
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

extension Never: View {}

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

extension HTMLElement: View where Content: View {
    private static func makeValue(_ view: borrowing Self, context: inout _ViewRenderingContext) -> _DomElement {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return _DomElement(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners()
        )
    }

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .element(
                makeValue(view, context: &context),
                Content._renderView(view.content, context: context)
            )
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        let value = makeValue(view, context: &context)

        return .element(
            _ReconcilerNode<DOM>.Element(
                value: value,
                context: &reconciler,
                childFactory: { [context] reconciler in
                    Content._makeNode(view.content, context: context, reconciler: &reconciler)
                }
            )
        )
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .element(element):
            let value = makeValue(view, context: &context)
            element.patch(value, context: &reconciler)

            Content._patchNode(
                view.content,
                context: context,
                node: element.child,
                reconciler: &reconciler
            )
        default:
            fatalError("Expected element node, got \(node)")
        }
    }
}

extension HTMLVoidElement: View {
    private static func makeValue(_ view: borrowing Self, context: inout _ViewRenderingContext) -> _DomElement {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return _DomElement(
            tagName: Tag.name,
            attributes: attributes,
            listerners: context.takeListeners()
        )
    }

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        let value = makeValue(view, context: &context)
        return .init(
            value: .element(
                value,
                .init(value: .nothing)
            )
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        let value = makeValue(view, context: &context)
        return .element(
            _ReconcilerNode<DOM>.Element(
                value: value,
                context: &reconciler,
                childFactory: { _ in .nothing }
            )
        )
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .element(element):
            let value = makeValue(view, context: &context)
            element.patch(value, context: &reconciler)
        default:
            fatalError("Expected element node, got \(node)")
        }
    }
}

extension HTMLText: View {
    public static func _renderView(_ view: consuming Self, context _: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .text(view.text)
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .text(.init(view.text, context: &reconciler))
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .text(text):
            text.patch(view.text, context: &reconciler)
        default:
            fatalError("Expected text node, got \(node)")
        }
    }
}

extension EmptyHTML: View {
    public static func _renderView(_: consuming Self, context _: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .nothing
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .nothing
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
    }
}

extension Optional: View where Wrapped: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        switch view {
        case let .some(view):
            return .init(value: .keyed(.trueKey, Wrapped._renderView(view, context: context)))
        case .none:
            return .init(value: .keyed(.falseKey, .init(value: .nothing)))
        }
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        switch view {
        case let .some(view):
            return .dynamic(
                .init(key: .trueKey, child: Wrapped._makeNode(view, context: context, reconciler: &reconciler), context: &reconciler)
            )
        case .none:
            return .dynamic(.init(key: .falseKey, child: .nothing, context: &reconciler))
        }
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .dynamic(dynamic):
            switch view {
            case let .some(view):
                dynamic.patch(
                    key: .trueKey,
                    context: &reconciler,
                    makeOrPatchNode: { [context] node, r in
                        if node == nil {
                            node = Wrapped._makeNode(view, context: context, reconciler: &r)
                        } else {
                            Wrapped._patchNode(view, context: context, node: node!, reconciler: &r)
                        }
                    }
                )
            case .none:
                dynamic.patch(
                    key: .falseKey,
                    context: &reconciler,
                    makeOrPatchNode: { node, r in
                        if node == nil {
                            node = .nothing
                        }
                    }
                )
            }
        default:
            fatalError("Expected dynamic node, got \(node)")
        }
    }
}

extension _HTMLConditional: View where TrueContent: View, FalseContent: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // TODO: think about collapsing structure keys better switch folding
        switch view.value {
        case let .trueContent(content):
            .init(value: .keyed(.trueKey, TrueContent._renderView(content, context: context)))
        case let .falseContent(content):
            .init(value: .keyed(.falseKey, FalseContent._renderView(content, context: context)))
        }
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        switch view.value {
        case let .trueContent(content):
            return .dynamic(
                .init(key: .trueKey, child: TrueContent._makeNode(content, context: context, reconciler: &reconciler), context: &reconciler)
            )
        case let .falseContent(content):
            return .dynamic(
                .init(
                    key: .falseKey,
                    child: FalseContent._makeNode(content, context: context, reconciler: &reconciler),
                    context: &reconciler
                )
            )
        }
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .dynamic(dynamic):
            switch view.value {
            case let .trueContent(content):
                dynamic.patch(
                    key: .trueKey,
                    context: &reconciler,
                    makeOrPatchNode: { [context] node, r in
                        if node == nil {
                            node = TrueContent._makeNode(content, context: context, reconciler: &r)
                        } else {
                            TrueContent._patchNode(content, context: context, node: node!, reconciler: &r)
                        }
                    }
                )
            case let .falseContent(content):
                dynamic.patch(
                    key: .falseKey,
                    context: &reconciler,
                    makeOrPatchNode: { [context] node, r in
                        if node == nil {
                            node = FalseContent._makeNode(content, context: context, reconciler: &r)
                        } else {
                            FalseContent._patchNode(content, context: context, node: node!, reconciler: &r)
                        }
                    }
                )
            }
        default:
            fatalError("Expected dynamic node, got \(node)")
        }
    }
}

extension _HTMLArray: View where Element: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // FIXME: this feels awkward
        .init(
            value: .dynamicList(
                view.value.map { Element._renderView($0, context: copy context) }
            )
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .dynamic(
            .init(
                view.value.enumerated().map { (index, element) in
                    (
                        key: .structure(index),
                        node: Element._makeNode(element, context: copy context, reconciler: &reconciler)
                    )
                },
                context: &reconciler
            )
        )
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .dynamic(dynamicList):
            // maybe we can optimize this
            let indexes = view.value.indices.map { _ViewKey.structure($0) }
            dynamicList.patch(
                indexes,
                context: &reconciler,
                makeOrPatchNode: { index, node, r in
                    if node == nil {
                        node = Element._makeNode(view.value[index], context: copy context, reconciler: &r)
                    } else {
                        Element._patchNode(view.value[index], context: copy context, node: node!, reconciler: &r)
                    }
                }
            )
        default:
            fatalError("Expected dynamic list node, got \(node)")
        }
    }
}

extension ForEach: View where Content: _KeyReadableView, Data: Collection {
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

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .dynamicList(
                view._data.map {
                    Content._renderView(
                        view._contentBuilder($0),
                        context: copy context
                    )
                }
            )
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .dynamic(
            .init(
                view._data
                    .map { value in
                        let view = view._contentBuilder(value)
                        return (key: view._key, node: Content.Value._makeNode(view._value, context: copy context, reconciler: &reconciler))
                    },
                context: &reconciler
            )
        )
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case let .dynamic(dynamicList):
            let views = view._data.map { value in view._contentBuilder(value) }
            dynamicList.patch(
                views.map { $0._key },
                context: &reconciler
            ) { [context] index, node, r in
                if node == nil {
                    node = Content.Value._makeNode(views[index]._value, context: context, reconciler: &r)
                } else {
                    Content.Value._patchNode(views[index]._value, context: context, node: node!, reconciler: &r)
                }
            }
        default:
            fatalError("Expected dynamic list node, got \(node)")
        }
    }
}

extension _AttributedElement: View where Content: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // TODO: make prepent from elementary available
        view.attributes.append(context.attributes)
        context.attributes = view.attributes

        return Content._renderView(view.content, context: context)
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        view.attributes.append(context.takeAttributes())
        context.attributes = view.attributes

        return Content._makeNode(view.content, context: context, reconciler: &reconciler)
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        view.attributes.append(context.takeAttributes())
        context.attributes = view.attributes

        Content._patchNode(
            view.content,
            context: context,
            node: node,
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
