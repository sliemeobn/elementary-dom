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
        tx: inout _TransactionContext
    ) -> _MountedNode {
        _MountedNode(
            view._data
                .map { value in
                    let view = view._contentBuilder(value)
                    return (key: view._key, node: Content.Value._makeNode(view._value, context: context, tx: &tx))
                },
            context: context
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        tx: inout _TransactionContext
    ) {
        let views = view._data.map { value in view._contentBuilder(value) }
        node.patch(
            views.map { $0._key },
            context: &tx,
            as: Content.Value._MountedNode.self,
        ) { index, node, context, tx in
            if node == nil {
                node = Content.Value._makeNode(views[index]._value, context: context, tx: &tx)
            } else {
                Content.Value._patchNode(views[index]._value, node: node!, tx: &tx)
            }
        }
    }
}
