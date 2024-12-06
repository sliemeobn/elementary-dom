import Elementary

// TODO: maybe this should not derive from HTML at all
// TODO: think about how the square the  thing with server side usage
// TODO: consuming sending Self... are we sure about this?
// TODO: maybe the _renderView should "reconcile" itself directly into a generic reconciler type instread of returning a _RenderedView (possible saving some allocations/currency types)
public protocol View: HTML where Content: View {
    static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView
    static func __applyContext(_ context: borrowing _ViewRenderingContext, to view: inout Self)
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
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return .init(
            value: .element(_DomElement(
                tagName: Tag.name,
                attributes: attributes,
                listerners: context.takeListeners()
            ), Content._renderView(view.content, context: context))
        )
    }
}

extension HTMLVoidElement: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var attributes = view._attributes
        attributes.append(context.takeAttributes())

        return .init(
            value: .element(_DomElement(
                tagName: Tag.name,
                attributes: attributes,
                listerners: context.takeListeners()
            ), .init(value: .nothing))
        )
    }
}

extension HTMLText: View {
    public static func _renderView(_ view: consuming Self, context _: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .text(view.text)
        )
    }
}

extension EmptyHTML: View {
    public static func _renderView(_: consuming Self, context _: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .nothing
        )
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
}

extension _HTMLArray: View where Element: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // FIXME: this feels awkward
        return .init(
            value: .dynamicList(
                view.value.map { Element._renderView($0, context: copy context) }
            )
        )
    }
}

extension _AttributedElement: View where Content: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // TODO: make prepent from elementary available
        view.attributes.append(context.attributes)
        context.attributes = view.attributes

        return Content._renderView(view.content, context: context)
    }
}

public extension View {
    static func __applyContext(_ context: borrowing _ViewRenderingContext, to view: inout Self) {
        print("ERROR: Unsupported view type \(Self.self) encountered. Please make sure to use @View on all custom views.")
        fatalError("Unsuppored View type enountered. Please make sure to use @View on all custom views.")
    }
}
