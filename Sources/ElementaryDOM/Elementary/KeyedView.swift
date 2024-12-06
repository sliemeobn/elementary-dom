public struct _KeyedView<Value: View>: View {
    var key: String
    var value: Value

    public static func _renderView(_ view: consuming Self, context: consuming _ViewRenderingContext) -> _RenderedView {
        return .init(
            value: .keyed(.explicit(view.key), Value._renderView(view.value, context: context))
        )
    }
}

public extension View {
    func key<K: LosslessStringConvertible>(_ key: K) -> _KeyedView<Self> {
        .init(key: key.description, value: self)
    }
}
