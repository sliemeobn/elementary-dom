import Elementary

final class CSSAnimatedValueSource<Value>: CSSValueLayerSource where Value: CSSAnimatable {
    var dependencies: DependencyTracker = .init()
    var lastValue: Value

    init(value: Value) {
        self.lastValue = value
    }

    func updateValue(_ value: Value, _ context: inout _RenderContext) {
        if value != lastValue {
            lastValue = value
            dependencies.invalidateAll(&context)
        }
    }

    func makeLayer(target: MountedStyleModifier<Value.CSSValue>) -> any CSSValueLayer<Value.CSSValue> {
        AnimatedLayer(source: self, target: target)
    }

    final class AnimatedLayer: Invalidateable, CSSValueLayer {
        typealias Instance = MountedStyleModifier<Value.CSSValue>
        var target: Instance
        let source: CSSAnimatedValueSource<Value>
        var animatedValue: AnimatedValue<Value>
        var isDirty: Bool = false

        var value: CSSPropertyLayerValue<Value.CSSValue>

        init(source: CSSAnimatedValueSource<Value>, target: Instance) {
            self.target = target
            self.source = source
            self.animatedValue = AnimatedValue(value: source.lastValue)
            self.value = .value(source.lastValue.cssValue)
        }

        func invalidate(_ context: inout _RenderContext) {
            _ = animatedValue.setValueAndReturnIfAnimationWasStarted(source.lastValue, context: context)

            if animatedValue.isAnimating {
                logWarning("animating not implemented")
                value = .value(animatedValue.presentation.cssValue)
            } else {
                value = .value(animatedValue.presentation.cssValue)
            }

            isDirty = true
            target.invalidate(&context)
        }
    }
}

protocol CSSValueLayerSource<CSSValue>: AnyObject {
    associatedtype CSSValue: CSSPropertyValue
    func makeLayer(target: MountedStyleModifier<CSSValue>) -> any CSSValueLayer<CSSValue>
}

protocol CSSValueLayer<Value>: AnyObject {
    associatedtype Value: CSSPropertyValue
    var isDirty: Bool { get set }
    var value: CSSPropertyLayerValue<Value> { get }
}

final class StyleModifier<SourcedValue>: DOMElementModifier, Invalidateable
where SourcedValue: CSSPropertyValue {
    typealias Value = any CSSValueLayerSource<SourcedValue>

    let upstream: StyleModifier?
    let layerNumber: Int
    var tracker: DependencyTracker = .init()

    var value: Value

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.value = value
        self.upstream = upstream[StyleModifier.key]
        self.layerNumber = (self.upstream?.layerNumber ?? 0) + 1
        self.upstream?.tracker.addDependency(self)
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        self.value = value
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        AnyUnmountable(MountedStyleModifier(node, self, &context))
    }

    func invalidate(_ context: inout _RenderContext) {
        self.tracker.invalidateAll(&context)
    }
}

final class MountedStyleModifier<CSSValue: CSSPropertyValue>: Unmountable, Invalidateable {
    let node: DOM.Node
    let accessor: DOM.StyleAccessor
    var layers: [any CSSValueLayer<CSSValue>]

    var isDirty: Bool = false

    init(_ node: DOM.Node, _ modifier: StyleModifier<CSSValue>, _ context: inout _CommitContext) {
        self.node = node
        self.accessor = context.dom.makeStyleAccessor(node, cssName: CSSValue.styleKey)
        self.layers = []

        layers.append(modifier.value.makeLayer(target: self))

        var modifier = modifier
        while let next = modifier.upstream {
            layers.append(next.value.makeLayer(target: self))
            modifier = next
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
            // set up update animations
            logWarning("animations not implemented")
        }

    }

    func unmount(_ context: inout _CommitContext) {
        layers.removeAll()
    }
}

private extension MountedStyleModifier {
    func reduceCombinedSingleValue() -> CSSValue? {
        guard let first = layers.first?.value.singleValue else { return nil }
        var combined = first
        for layer in layers.dropFirst() {
            guard let next = layer.value.singleValue else { return nil }
            combined.combineWith(next)
        }
        return combined
    }
}

struct ValueSampleTrack<Value> {
    var values: [(Double, Value)]
}

protocol CSSAnimatable: AnimatableVectorConvertible {
    associatedtype CSSValue: CSSPropertyValue
    var cssValue: CSSValue { get }
}

protocol CSSPropertyValue {
    static var styleKey: String { get }
    var cssString: String { get }
    mutating func combineWith(_ other: Self)
}

enum CSSPropertyLayerValue<CSSValue: CSSPropertyValue> {
    case value(CSSValue)
    case animated([ValueSampleTrack<CSSValue>])

    var singleValue: CSSValue? {
        switch self {
        case .value(let value):
            value
        case .animated(_):
            nil
        }
    }
}
