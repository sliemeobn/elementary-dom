import Elementary

final class TransformModifier: DOMElementModifier {
    typealias Value = CSSTransform.AnyFunction

    let upstream: TransformModifier?
    let layerNumber: Int

    var value: CSSTransform.AnyFunction.ValueSource

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.value = value.makeSource()
        self.upstream = upstream[TransformModifier.key]
        self.layerNumber = (self.upstream?.layerNumber ?? 0) + 1
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        switch (self.value, value) {
        case (.rotation(let rotation), .rotation(let newRotation)):
            rotation.updateValue(newRotation, &context)
        case (.translation(let translation), .translation(let newTranslation)):
            translation.updateValue(newTranslation, &context)
        default:
            assertionFailure("Cannot update value of different type")
        }
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        AnyUnmountable(MountedStyleModifier(node, makeLayers(&context), &context))
    }

    private func makeLayers(_ context: inout _CommitContext) -> [AnyCSSAnimatedValueInstance<CSSTransform>] {
        [AnyCSSAnimatedValueInstance(value.makeInstance())]
    }
}

extension CSSTransform.AnyFunction {
    enum ValueSource {
        case rotation(CSSValueSource<CSSRotation>)
        case translation(CSSValueSource<CSSTranslation>)

        func makeInstance() -> AnyCSSAnimatedValueInstance<CSSTransform> {
            switch self {
            case .rotation(let value):
                AnyCSSAnimatedValueInstance(value.makeInstance())
            case .translation(let value):
                AnyCSSAnimatedValueInstance(value.makeInstance())
            }
        }
    }

    func makeSource() -> ValueSource {
        switch self {
        case .rotation(let value):
            .rotation(CSSValueSource(value: value))
        case .translation(let value):
            .translation(CSSValueSource(value: value))
        }
    }
}
