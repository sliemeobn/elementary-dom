import Elementary

final class OpacityModifier: DOMElementModifier {
    typealias Value = CSSOpacity

    let upstream: OpacityModifier?
    let layerNumber: Int

    var value: CSSValueSource<CSSOpacity>

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.value = CSSValueSource(value: value)
        self.upstream = upstream[OpacityModifier.key]
        self.layerNumber = (self.upstream?.layerNumber ?? 0) + 1
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        self.value.updateValue(value, &context)
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        // TODO: upstreams
        AnyUnmountable(MountedStyleModifier(node, [self.value.makeInstance()], &context))
    }
}
