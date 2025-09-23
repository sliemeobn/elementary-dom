extension View {
    public func opacity(_ value: Double) -> some View<Self.Tag> {
        StyleEffectView<CSSOpacity, Self>(value: CSSOpacity(value: value), wrapped: self)
    }
}

struct CSSOpacity {
    var value: Double

    init(value: Double) {
        self.value = min(max(value, 0), 1)
    }
}

extension CSSOpacity: CSSAnimatable {
    var cssValue: Self { self }
    init(_ animatableVector: AnimatableVector) {
        guard case .d1(let value) = animatableVector else {
            fatalError("Unsupported animatable vector")
        }
        self.value = Double(value)
    }

    var animatableVector: AnimatableVector {
        .d1(Float(value))
    }
}

extension CSSOpacity: CSSPropertyValue {
    static var styleKey: String = "opacity"

    var cssString: String { "\(value)" }

    mutating func combineWith(_ other: CSSOpacity) {
        value *= other.value
    }
}

struct StyleEffectView<SourceValue: CSSAnimatable, Wrapped: View>: View {
    typealias Tag = Wrapped.Tag
    var value: SourceValue
    var wrapped: Wrapped

    typealias _MountedNode = _StatefulNode<CSSAnimatedValueSource<SourceValue>, Wrapped._MountedNode>

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        let source = CSSAnimatedValueSource<SourceValue>(value: view.value)
        let modifier = StyleModifier<SourceValue.CSSValue>(
            value: source,
            upstream: context.modifiers,
            &reconciler
        )

        var context = copy context
        context.modifiers[StyleModifier<SourceValue.CSSValue>.key] = modifier

        return .init(
            state: source,
            child: Wrapped._makeNode(view.wrapped, context: context, reconciler: &reconciler)
        )
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
