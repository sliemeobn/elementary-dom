public struct _KeyedView<Value: View>: View {
    var key: String
    var value: Value

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        .init(
            value: .keyed(.explicit(view.key), Value._renderView(view.value, context: context))
        )
    }

    public static func _makeNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        reconciler: inout _ReconcilerBatch<DOM>
    ) -> _ReconcilerNode<DOM> {
        .dynamic(
            .init(
                key: .explicit(view.key),
                child: Value._makeNode(view.value, context: context, reconciler: &reconciler),
                context: &reconciler
            )
        )
    }

    public static func _patchNode<DOM>(
        _ view: consuming Self,
        context: consuming _ViewRenderingContext,
        node: borrowing _ReconcilerNode<DOM>,
        reconciler: inout _ReconcilerBatch<DOM>
    ) {
        switch node {
        case .dynamic(let dynamic):
            // TODO: maybe optimize for "array-of-one" case
            dynamic.patch(
                key: .explicit(view.key),
                context: &reconciler,
                makeOrPatchNode: { [context] node, r in
                    if node == nil {
                        node = Value._makeNode(view.value, context: context, reconciler: &r)
                    } else {
                        Value._patchNode(view.value, context: context, node: node!, reconciler: &r)
                    }
                }
            )
        default:
            fatalError("Expected dynamic node, got \(node)")
        }
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
