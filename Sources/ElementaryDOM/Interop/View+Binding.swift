import Elementary

public extension View where Tag == HTMLTag.input {
    consuming func bindValue(_ value: Binding<String>) -> some View {
        DOMEffectView<BindingModifier<TextBindingConfiguration>, Self>(value: value, wrapped: self)
    }

    consuming func bindValue(_ value: Binding<Double?>) -> some View {
        DOMEffectView<BindingModifier<NumberBindingConfiguration>, Self>(value: value, wrapped: self)
    }

    consuming func bindChecked(_ value: Binding<Bool>) -> some View {
        DOMEffectView<BindingModifier<CheckboxBindingConfiguration>, Self>(value: value, wrapped: self)
    }
}

struct DOMEffectView<Effect: DOMElementModifier, Wrapped: View>: View {
    var value: Effect.Value
    var wrapped: Wrapped

    typealias _MountedNode = _StatefulNode<Effect, Wrapped._MountedNode>

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let effect = Effect(value: view.value, upstream: context.modifiers, &reconciler)
        context.modifiers[Effect.key] = effect

        return .init(state: effect, child: Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler))
    }

    static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.state.updateValue(view.value, &reconciler)
        Wrapped._patchNode(view.wrapped, node: &node.child, reconciler: &reconciler)
    }
}
