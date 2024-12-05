import Elementary

extension _HTMLTuple2: View where V0: View, V1: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
            ])
        )
    }
}

extension _HTMLTuple3: View where V0: View, V1: View, V2: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
            ])
        )
    }
}

extension _HTMLTuple4: View where V0: View, V1: View, V2: View, V3: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
            ])
        )
    }
}

extension _HTMLTuple5: View where V0: View, V1: View, V2: View, V3: View, V4: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
                V4._renderView(view.v4, context: copy context),
            ])
        )
    }
}

extension _HTMLTuple6: View where V0: View, V1: View, V2: View, V3: View, V4: View, V5: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .staticList([
                V0._renderView(view.v0, context: copy context),
                V1._renderView(view.v1, context: copy context),
                V2._renderView(view.v2, context: copy context),
                V3._renderView(view.v3, context: copy context),
                V4._renderView(view.v4, context: copy context),
                V5._renderView(view.v5, context: copy context),
            ])
        )
    }
}

#if !hasFeature(Embedded)
extension _HTMLTuple: View where repeat each Child: View {
    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        var renderedChildren: [_RenderedView] = []
        // renderedChildren.reserveCapacity(view.value.count)

        func addChild<C: View>(_ child: consuming sending C) {
            renderedChildren.append(C._renderView(child, context: copy context))
        }

        repeat addChild(each view.value)

        return .init(
            value: .staticList(renderedChildren)
        )
    }
}
#endif
