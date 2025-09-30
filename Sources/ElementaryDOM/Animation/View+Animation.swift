struct _TransactionModifierView<Wrapped: View, Value: Equatable>: View {
    public typealias Tag = Wrapped.Tag
    public typealias Content = Never
    public typealias _MountedNode = _StatefulNode<State, Wrapped._MountedNode>

    struct State {
        var value: Value
    }

    var view: Wrapped
    var value: Value
    var transactionModifier: (inout Transaction) -> Void

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let node = Wrapped._makeNode(view.view, context: context, reconciler: &reconciler)
        return .init(state: .init(value: view.value), child: node)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        if node.state.value != view.value {
            node.state.value = view.value
            view.transactionModifier(&reconciler.transaction)
        }

        Wrapped._patchNode(view.view, node: node.child, reconciler: &reconciler)
    }
}

extension View {
    public func transaction<Value: Equatable>(
        value: Value,
        _ transform: @escaping (inout Transaction) -> Void
    ) -> some View<Self.Tag> {
        _TransactionModifierView(view: self, value: value, transactionModifier: transform)
    }

    public func animation<Value: Equatable>(
        _ animation: Animation?,
        value: Value,
    ) -> some View<Self.Tag> {
        _TransactionModifierView(view: self, value: value) { $0.animation = animation }
    }
}
