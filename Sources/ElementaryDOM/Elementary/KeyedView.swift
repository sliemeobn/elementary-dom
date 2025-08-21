public struct _KeyedView<Value: View>: View {
    public typealias _MountedNode = _KeyedNode<Value._MountedNode>

    var key: _ViewKey
    var value: Value

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(
            key: view.key,
            child: Value._makeNode(view.value, context: context, reconciler: &reconciler),
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(
            key: view.key,
            context: &reconciler,
            makeOrPatchNode: { [context] node, r in
                if node == nil {
                    node = Value._makeNode(view.value, context: context, reconciler: &r)
                } else {
                    Value._patchNode(view.value, context: context, node: &node!, reconciler: &r)
                }
            }
        )
    }
}

public extension View {
    func key<K: LosslessStringConvertible>(_ key: K) -> _KeyedView<Self> {
        .init(key: _ViewKey(key), value: self)
    }
}

public protocol _KeyReadableView: View {
    associatedtype Value: View

    var _key: _ViewKey { get }
    var _value: Value { get }
}

extension _KeyedView: _KeyReadableView {
    public var _key: _ViewKey {
        key
    }

    public var _value: Value {
        value
    }
}
