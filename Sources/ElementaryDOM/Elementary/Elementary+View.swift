import Elementary

// TODO: maybe this should not derive from HTML at all
// TODO: think about how the square the  thing with server side usage
// TODO: consuming sending Self... are we sure about this?
// TODO: maybe the _renderView should "reconcile" itself directly into a generic reconciler type instread of returning a _RenderedView (possible saving some allocations/currency types)
public protocol View: HTML where Content: View {
    static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView
}

public extension View where Content == Never {
    var content: Content {
        fatalError("This should never be called")
    }
}

extension Never: View {}

public struct _ViewRenderingContext {
    var eventListeners: _DomEventListenerStorage = .init()
    var attributes: _AttributeStorage

    public static var empty: Self {
        .init(attributes: .none)
    }
}

public extension View {
    static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .function(.from(view, context: context))
        )
    }
}

extension HTMLElement: View where Content: View {
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var attributes = view._attributes
        attributes.append(context.attributes)

        return .init(
            value: .element(_DomElement(
                tagName: Tag.name,
                attributes: attributes,
                listerners: context.eventListeners
            ), Content._renderView(view.content, context: .empty))
        )
    }
}

extension HTMLVoidElement: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var attributes = view._attributes
        attributes.append(context.attributes)

        return .init(
            value: .element(_DomElement(
                tagName: Tag.name,
                attributes: attributes,
                listerners: context.eventListeners
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
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        switch view {
        case let .some(view):
            return Wrapped._renderView(view, context: context)
        case .none:
            return .init(
                value: .nothing
            )
        }
    }
}

extension _HTMLConditional: View where TrueContent: View, FalseContent: View {
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        switch view.value {
        case let .trueContent(content):
            TrueContent._renderView(content, context: context)
        case let .falseContent(content):
            FalseContent._renderView(content, context: context)
        }
    }
}

extension _HTMLArray: View where Element: View {
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var renderedChildren: [_RenderedView] = []
        renderedChildren.reserveCapacity(view.value.count)

        func addChild<C: View>(_ child: consuming sending C) {
            renderedChildren.append(C._renderView(child, context: copy context))
        }

        // map does not work because of sending things, but the whole sending thing might go away once MainActor stuff is figured out
        for child in view.value {
            addChild(child)
        }

        return .init(
            value: .list(renderedChildren)
        )
    }
}

extension _AttributedElement: View where Content: View {
    public static func _renderView(_ view: consuming sending Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        // TODO: make prepent from elementary available
        view.attributes.append(context.attributes)
        context.attributes = view.attributes

        return Content._renderView(view.content, context: context)
    }
}
