import Reactivity

public extension View {
    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self> {
        _EnvironmentView(wrapped: self, key: key, value: value, isEqual: nil)
    }

    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self>
    where V: Equatable {
        _EnvironmentView(wrapped: self, key: key, value: value, isEqual: ==)
    }

    consuming func environment(_ key: EnvironmentValues._Key<String>, _ value: String) -> _EnvironmentView<String, Self> {
        _EnvironmentView(wrapped: self, key: key, value: value, isEqual: String.utf8Equals)
    }

    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self>
    where V: Equatable & AnyObject {
        _EnvironmentView(wrapped: self, key: key, value: value, isEqual: ===)
    }

    consuming func environment<V>(_ key: EnvironmentValues._Key<V>, _ value: V) -> _EnvironmentView<V, Self>
    where V: AnyObject {
        _EnvironmentView(wrapped: self, key: key, value: value, isEqual: ===)
    }

    consuming func environment<V: ReactiveObject>(_ object: V) -> _EnvironmentView<V, Self> {
        _EnvironmentView(wrapped: self, key: V.environmentKey, value: object, isEqual: ===)
    }
}

public struct _EnvironmentView<V, Wrapped: View>: View {
    public typealias _MountedNode = _StatefulNode<EnvironmentValues._Box<V>, Wrapped._MountedNode>
    public typealias Tag = Wrapped.Tag

    let wrapped: Wrapped
    let key: EnvironmentValues._Key<V>
    let value: V
    let isEqual: ((V, V) -> Bool)?

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        tx: inout _TransactionContext
    ) -> _MountedNode {
        var context = copy context
        let box = EnvironmentValues._Box<V>(view.value)
        context.environment.boxes[view.key.propertyID] = box

        return .init(state: box, child: Wrapped._makeNode(view.wrapped, context: context, tx: &tx))
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        tx: inout _TransactionContext
    ) {
        // IMPORTANT: _value does not cause access tracking!
        if view.isEqual?(node.state._value, view.value) ?? true {
            node.state._value = view.value
        } else {
            // TODO: rework this to explicit dependencies
            // NOTE: a bit of a hack to allow dependent functions to run in the same transaction run
            tx.scheduler.withAmbientTransactionContext(
                &tx,
                {
                    node.state.value = view.value
                }
            )
        }

        Wrapped._patchNode(view.wrapped, node: node.child, tx: &tx)
    }
}
