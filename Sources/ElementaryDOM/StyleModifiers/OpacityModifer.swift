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
        guard value != self.value else { return }
        self.value = value
        dependencies.invalidateAll(&context)
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        AnyUnmountable(MountedOpacityModifier(node, self, &context))
    }
}

final class MountedOpacityModifier: Unmountable, Invalidateable {
    let accessor: DOM.StyleAccessor
    var values: [CSSAnimatedValueBox<CSSOpacity>]
    var scheduler: Scheduler?  // TODO: pass this in commit context

    let node: DOM.Node
    var animations: [DOM.Animation]

    var isDirty: Bool = false

    init(_ node: DOM.Node, _ source: OpacityModifier, _ context: inout _CommitContext) {
        self.node = node
        self.accessor = context.dom.makeStyleAccessor(node, cssName: CSSOpacity.styleKey)
        self.values = []
        self.animations = []

        var source = source
        let invalidateable = AnyInvalidateable(self)
        let box = CSSAnimatedValueBox(source: { source.value }, target: invalidateable)
        values.append(box)
        source.dependencies.addDependency(box)
        while let next = source.upstream {
            let box = CSSAnimatedValueBox(source: { next.value }, target: invalidateable)
            source.dependencies.addDependency(box)
            values.append(box)
            source = next
        }

        self.values.reverse()

        updateDOMNode(&context)
    }

    func invalidate(_ context: inout _RenderContext) {
        guard !isDirty else { return }
        isDirty = true
        context.scheduler.addNodeAction(CommitAction(run: updateDOMNode(_:)))
        scheduler = context.scheduler  // FIXME: this is a bit hacky
    }

    func updateDOMNode(_ context: inout _CommitContext) {
        logTrace("updating opacity modifier")
        if let combined = reduceCombinedSingleValue() {
            logTrace("setting combined value \(combined.cssString)")
            clearAllAnimations()
            accessor.set(combined.cssString)
        } else {
            startOrUpdateAnimations(&context)
        }

        isDirty = false
        for value in values {
            value.isDirty = false
        }
    }

    func unmount(_ context: inout _CommitContext) {
        values.removeAll()
    }

    private func clearAllAnimations() {
        guard !animations.isEmpty else { return }
        for animation in animations {
            animation.cancel()
        }
        animations.removeAll(keepingCapacity: true)
    }

    private func startOrUpdateAnimations(_ context: inout _CommitContext) {
        if animations.isEmpty {
            logTrace("starting animations")
            animations.reserveCapacity(values.count)

            for value in values {
                animations.append(
                    context.dom.animateElement(
                        node,
                        DOM.Animation.KeyframeEffect(value.value, isFirst: value === values.first)
                    ) { [scheduler] in
                        logTrace("animation finished")
                        scheduler?.registerAnimation(AnyAnimatable(value))
                    }
                )
            }
        } else {
            for (animation, value) in zip(animations, values) {
                guard value.isDirty else { continue }
                logTrace("updating animation")
                animation.update(DOM.Animation.KeyframeEffect(value.value, isFirst: value === values.first))
            }
        }
    }

    private func reduceCombinedSingleValue() -> CSSOpacity? {
        guard let first = values.first?.value.singleValue else { return nil }
        var combined = first
        for layer in values.dropFirst() {
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
