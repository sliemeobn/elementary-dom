extension View {
    /// Sets the opacity of the view.
    ///
    /// Use this modifier to control the transparency of a view and its content.
    /// Opacity values range from 0 (fully transparent) to 1 (fully opaque).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// div { "Semi-transparent" }
    ///     .opacity(0.5)
    ///
    /// // Animate opacity changes
    /// withAnimation {
    ///     isVisible.toggle()
    /// }
    /// div { "Fading content" }
    ///     .opacity(isVisible ? 1.0 : 0.0)
    /// ```
    ///
    /// - Parameter value: The opacity value, from 0 (invisible) to 1 (fully visible).
    /// - Returns: A view with the specified opacity.
    public func opacity(_ value: Double) -> some View<Self.Tag> {
        DOMEffectView<OpacityModifier, Self>(value: CSSOpacity(value: value), wrapped: self)
    }

    /// Rotates the view by the specified angle.
    ///
    /// Use this modifier to apply a 2D rotation transform to a view.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// div { "Rotated" }
    ///     .rotationEffect(.degrees(45))
    ///
    /// // Rotate around a custom anchor point
    /// div { "Spinning" }
    ///     .rotationEffect(.degrees(rotation), anchor: .topLeading)
    ///
    /// // Animate rotation
    /// withAnimation {
    ///     rotation += 90
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - angle: The angle to rotate by.
    ///   - anchor: The point around which to rotate. Default is `.center`.
    /// - Returns: A view rotated by the specified angle.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View<Self.Tag> {
        DOMEffectView<TransformModifier, Self>(value: .rotation(CSSTransform.Rotation(angle: angle, anchor: anchor)), wrapped: self)
    }

    /// Offsets the view by the specified horizontal and vertical distances.
    ///
    /// Use this modifier to move a view from its natural position without
    /// affecting the layout of other views.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// div { "Offset content" }
    ///     .offset(x: 50, y: 20)
    ///
    /// // Animate position changes
    /// withAnimation {
    ///     xPosition += 100
    /// }
    /// div { "Moving" }
    ///     .offset(x: xPosition)
    /// ```
    ///
    /// - Parameters:
    ///   - x: The horizontal offset in pixels. Default is 0.
    ///   - y: The vertical offset in pixels. Default is 0.
    /// - Returns: A view offset by the specified amounts.
    public func offset(x: Float = 0, y: Float = 0) -> some View<Self.Tag> {
        DOMEffectView<TransformModifier, Self>(value: .translation(CSSTransform.Translation(x: x, y: y)), wrapped: self)
    }
}
