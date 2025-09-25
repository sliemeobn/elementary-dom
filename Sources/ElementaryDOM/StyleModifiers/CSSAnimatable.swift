protocol CSSAnimatable: AnimatableVectorConvertible {
    associatedtype CSSValue: CSSPropertyValue
    var cssValue: CSSValue { get }
}

protocol CSSPropertyValue {
    static var styleKey: String { get }
    var cssString: String { get }
    mutating func combineWith(_ other: Self)
}

struct SampledAnimationTrack<Value> {
    var startTime: Double
    var duration: Double
    var sampledFrames: [Value]
}

enum CSSPropertyLayerValue<CSSValue: CSSPropertyValue> {
    case value(CSSValue)
    case animated(SampledAnimationTrack<CSSValue>)

    var singleValue: CSSValue? {
        switch self {
        case .value(let value):
            value
        case .animated(_):
            nil
        }
    }
}

extension DOM.Animation.KeyframeEffect {
    init<CSSValue: CSSPropertyValue>(_ value: CSSPropertyLayerValue<CSSValue>, isFirst: Bool) {
        self.property = CSSValue.styleKey
        self.composite = isFirst ? .replace : .accumulate

        switch value {
        case .value(let value):
            self.values = [value.cssString]
            self.duration = 0
        case .animated(let track):
            self.values = track.sampledFrames.map { $0.cssString }
            self.duration = Int(track.duration * 1000)
        }
    }

}

final class CSSAnimatedValueBox<Value: CSSAnimatable>: Invalidateable {
    let source: () -> Value
    private var animatedValue: AnimatedValue<Value>
    var isDirty: Bool = false
    var target: AnyInvalidateable

    // TODO: add unmount

    var value: CSSPropertyLayerValue<Value.CSSValue>

    init(source: @escaping () -> Value, target: AnyInvalidateable) {
        self.target = target
        self.source = source
        self.animatedValue = AnimatedValue(value: source())
        self.value = .value(animatedValue.presentation.cssValue)
    }

    func invalidate(_ context: inout _RenderContext) {
        _ = animatedValue.setValueAndReturnIfAnimationWasStarted(source(), context: context)
        updateValue(&context)
    }

    func progressAnimation(_ context: inout _RenderContext) -> Bool {
        animatedValue.progressToTime(context.currentFrameTime)

        updateValue(&context)
        return false  // NOTE: this is always false because send down chunks of peaked values
    }

    private func updateValue(_ context: inout _RenderContext) {
        if animatedValue.isAnimating {
            let samples = 40.0
            let maxDuration = 1.0
            let frames = animatedValue.peekFutureValues(
                stride(from: context.currentFrameTime, through: context.currentFrameTime + maxDuration, by: 1.0 / samples)
            )

            value = .animated(
                SampledAnimationTrack(startTime: context.currentFrameTime, duration: maxDuration, sampledFrames: frames.map { $0.cssValue })
            )
        } else {
            value = .value(animatedValue.presentation.cssValue)
        }

        isDirty = true
        target.invalidate(&context)
    }
}

extension AnyAnimatable {
    init<Value: CSSAnimatable>(_ value: CSSAnimatedValueBox<Value>) {
        self.progressAnimation = value.progressAnimation(_:)
    }
}
