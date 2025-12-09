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
    typealias Tag = Wrapped.Tag
    var value: Effect.Value
    var wrapped: Wrapped

    typealias _MountedNode = _StatefulNode<Effect, Wrapped._MountedNode>

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        tx: inout _TransactionContext
    ) -> _MountedNode {
        let effect = Effect(value: view.value, upstream: context.modifiers, &tx)

        #if hasFeature(Embedded)
        if __omg_this_was_annoying_I_am_false {
            var context = _CommitContext(
                dom: JSKitDOMInteractor(root: .global),
                scheduler: Scheduler(dom: JSKitDOMInteractor(root: .global)),
                currentFrameTime: 0
            )
            // force inclusion of types used in mount
            _ = effect.mount(.init(.init()), &context)
        }
        #endif

        var context = copy context
        context.modifiers[Effect.key] = effect

        return .init(state: effect, child: Wrapped._makeNode(view.wrapped, context: context, tx: &tx))
    }

    static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        tx: inout _TransactionContext
    ) {
        node.state.updateValue(view.value, &tx)
        Wrapped._patchNode(view.wrapped, node: node.child, tx: &tx)
    }
}
