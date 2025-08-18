public struct _KeyedView<Value: View>: View {
    public typealias Node = Dynamic<Value.Node>

    var key: String
    var value: Value

    public static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch
    ) -> Node {
        .init(
            key: .explicit(view.key),
            child: Value._makeNode(view.value, context: context, reconciler: &reconciler),
            context: &reconciler
        )
    }

    public static func _patchNode(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: inout Node,
        reconciler: inout _ReconcilerBatch
    ) {
        node.patch(
            key: .explicit(view.key),
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
        .init(key: key.description, value: self)
    }
}

public protocol _KeyReadableView: View {
    associatedtype Value: View

    var _key: _ViewKey { get }
    var _value: Value { get }
}

extension _KeyedView: _KeyReadableView {
    public var _key: _ViewKey {
        .explicit(key)
    }

    public var _value: Value {
        value
    }
}
