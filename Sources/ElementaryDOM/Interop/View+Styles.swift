extension View {
    public func opacity(_ value: Double) -> some View<Self.Tag> {
        DOMEffectView<OpacityModifier, Self>(value: CSSOpacity(value: value), wrapped: self)
    }

    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View<Self.Tag> {
        DOMEffectView<TransformModifier, Self>(value: .rotation(CSSRotation(angle: angle, anchor: anchor)), wrapped: self)
    }

    public func offset(x: Float = 0, y: Float = 0) -> some View<Self.Tag> {
        DOMEffectView<TransformModifier, Self>(value: .translation(CSSTranslation(x: x, y: y)), wrapped: self)
    }
}
