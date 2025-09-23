import Elementary

struct CSSOpacity {
    var value: Double

    init(value: Double) {
        self.value = min(max(value, 0), 1)
    }
}

final class OpacityModifier: DOMElementModifier {
    typealias Value = CSSOpacity

    var dependencies: DependencyTracker = .init()
    let upstream: OpacityModifier?
    let layerNumber: Int

    var value: Value

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.value = value
        self.upstream = upstream[OpacityModifier.key]
        self.layerNumber = (self.upstream?.layerNumber ?? 0) + 1
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        self.value = value
        dependencies.invalidateAll(&context)
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        AnyUnmountable(MountedOpacityModifier(node, self, &context))
    }
}

final class MountedOpacityModifier: Unmountable, Invalidateable {
    let node: DOM.Node
    let accessor: DOM.StyleAccessor
    var layers: [CSSAnimatedValueBox<CSSOpacity>]

    var isDirty: Bool = false

    init(_ node: DOM.Node, _ source: OpacityModifier, _ context: inout _CommitContext) {
        self.node = node
        self.accessor = context.dom.makeStyleAccessor(node, cssName: CSSOpacity.styleKey)
        self.layers = []

        var source = source
        let invalidateable = AnyInvalidateable(self)
        let box = CSSAnimatedValueBox(source: { source.value }, target: invalidateable)
        layers.append(box)
        source.dependencies.addDependency(box)
        while let next = source.upstream {
            let box = CSSAnimatedValueBox(source: { next.value }, target: invalidateable)
            source.dependencies.addDependency(box)
            layers.append(box)
            source = next
        }

        self.layers.reverse()

        updateDOMNode(&context)
    }

    func invalidate(_ context: inout _RenderContext) {
        guard !isDirty else { return }
        isDirty = true
        context.scheduler.addNodeAction(CommitAction(run: updateDOMNode(_:)))
    }

    func updateDOMNode(_ context: inout _CommitContext) {
        isDirty = false
        if let combined = reduceCombinedSingleValue() {
            accessor.set(combined.cssString)
        } else {

        }

    }

    func unmount(_ context: inout _CommitContext) {
        layers.removeAll()
    }

    private func reduceCombinedSingleValue() -> CSSOpacity? {
        guard let first = layers.first?.value.singleValue else { return nil }
        var combined = first
        for layer in layers.dropFirst() {
            guard let next = layer.value.singleValue else { return nil }
            combined.combineWith(next)
        }
        return combined
    }
}

extension CSSOpacity: CSSAnimatable {
    var cssValue: CSSOpacity { self }
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
