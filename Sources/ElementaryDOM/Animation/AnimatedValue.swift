struct AnimationInstance {
    struct TrackingReference {
        let instanceID: AnimationTracker.InstanceID
        let tracker: AnimationTracker
    }

    let startTime: Double
    let animation: Animation
    let trackingReference: TrackingReference?

    init(startTime: Double, animation: Animation, trackingReference: TrackingReference? = nil) {
        self.startTime = startTime
        self.animation = animation
        self.trackingReference = trackingReference
    }

    func reportLogicallyComplete() {
        trackingReference?.tracker.reportLogicallyComplete(trackingReference!.instanceID)
    }

    func reportRemoved() {
        trackingReference?.tracker.reportRemoved(trackingReference!.instanceID)
    }
}

private struct RunningAnimation {
    let instance: AnimationInstance
    let target: AnimatableVector

    borrowing func animate(time: Double, context: inout AnimationContext, additionalVector: AnimatableVector?) -> AnimatableVector? {
        if let additionalVector {
            instance.animation.animate(value: target + additionalVector, time: time - instance.startTime, context: &context)
        } else {
            instance.animation.animate(value: target, time: time - instance.startTime, context: &context)
        }
    }
}

struct AnimatedValue<Value: AnimatableVectorConvertible>: ~Copyable {
    private var runningAnimations: [RunningAnimation] = []
    private var currentTarget: Value
    private var currentAnimationValue: Value

    private var animationBase: AnimatableVector
    private var context: AnimationContext

    var model: Value { borrowing get { currentTarget } }
    var presentation: Value { borrowing get { currentAnimationValue } }
    var isAnimating: Bool { borrowing get { !runningAnimations.isEmpty } }

    init(value: Value) {
        self.animationBase = value.animatableVector
        self.currentTarget = value
        self.currentAnimationValue = value
        self.context = AnimationContext()
    }

    mutating func setValue(_ value: Value) {
        self.animationBase = value.animatableVector
        self.currentTarget = value
        self.currentAnimationValue = value

        removeAnimations(upThrough: runningAnimations.endIndex - 1, skipBaseUpdate: true)
    }

    mutating func animate(to value: Value, animation: AnimationInstance) {
        self.progressToTime(animation.startTime)
        var animationTarget = value.animatableVector - currentTarget.animatableVector

        if let previous = runningAnimations.last {
            let elapsedTime = animation.startTime - previous.instance.startTime
            let shouldMerge = animation.animation.shouldMerge(
                previous: previous.instance.animation,
                value: previous.target,
                time: elapsedTime,
                context: &context
            )

            if shouldMerge {
                self.animationBase = currentAnimationValue.animatableVector
                self.removeAnimations(upThrough: runningAnimations.endIndex - 1, skipBaseUpdate: true)
                animationTarget = value.animatableVector - self.animationBase
            }
        }

        self.currentTarget = value
        runningAnimations.append(RunningAnimation(instance: animation, target: animationTarget))
    }

    mutating func progressToTime(_ time: Double) {
        guard isAnimating else { return }

        let (animatedVector, finishedAnimationIndex) = calculateAnimationAtTime(
            time,
            runningAnimations: runningAnimations,
            context: &context
        )

        if let finishedAnimationIndex {
            removeAnimations(upThrough: finishedAnimationIndex)
        }

        if isAnimating {
            self.currentAnimationValue = Value(animationBase + animatedVector)
        } else {
            // NOTE: avoid floating point weirdness
            self.currentAnimationValue = self.currentTarget
            self.animationBase = self.currentTarget.animatableVector
        }
    }

    // TODO: figure out the shape for this
    func peekFutureValues(_ times: StrideThrough<Double>) -> [Value] {
        var results: [Value] = []
        var contextCopy = context
        var runningAnimations = runningAnimations[...]
        var base = animationBase

        results.reserveCapacity(times.underestimatedCount)

        for time in times {
            let (animatedVector, completedIndex) = calculateAnimationAtTime(
                time,
                runningAnimations: runningAnimations,
                context: &contextCopy
            )

            if let completedIndex {
                for i in runningAnimations.startIndex...completedIndex {
                    base += runningAnimations[i].target
                }
                runningAnimations = runningAnimations[(completedIndex + 1)...]
            }

            if runningAnimations.isEmpty {
                results.append(self.currentTarget)
                break
            }

            results.append(Value(base + animatedVector))
        }
        return results
    }

    private mutating func removeAnimations(upThrough index: Int, skipBaseUpdate: Bool = false) {
        for i in 0...index {
            runningAnimations[i].instance.reportRemoved()
            if !skipBaseUpdate {
                self.animationBase += runningAnimations[i].target
            }
        }
        runningAnimations.removeSubrange(0...index)
    }
}

private func calculateAnimationAtTime<AnimationList>(
    _ time: Double,
    runningAnimations: AnimationList,
    context: inout AnimationContext,
) -> (animatedVector: AnimatableVector, finishedAnimationIndex: AnimationList.Index?)
where AnimationList: Collection<RunningAnimation> {
    guard runningAnimations.count > 1 else {
        assert(runningAnimations.first != nil, "Running animations should not be empty")
        if let vector = runningAnimations.first!.animate(time: time, context: &context, additionalVector: nil) {
            return (vector, nil)
        } else {
            return (runningAnimations.first!.target, runningAnimations.indices.first)
        }
    }

    var finishedAnimationIndex: AnimationList.Index?
    var index = runningAnimations.startIndex

    let zero = AnimatableVector.zero(runningAnimations.first!.target)

    var totalAnimationVector = zero
    var carryOverVector = zero

    while index < runningAnimations.endIndex {
        let runningAnimation = runningAnimations[index]

        if let vector = runningAnimation.animate(time: time, context: &context, additionalVector: carryOverVector) {
            totalAnimationVector += vector
            carryOverVector = runningAnimation.target - vector
        } else {
            finishedAnimationIndex = index
            //totalAnimationVector = zero
            carryOverVector = zero
        }

        runningAnimations.formIndex(after: &index)
    }

    return (totalAnimationVector, finishedAnimationIndex)
}

internal extension AnimatedValue {
    mutating func setValueAndReturnIfAnimationWasStarted(_ value: Value, context: inout _RenderContext) -> Bool {
        guard value != currentTarget else { return false }

        let wasAnimating = isAnimating

        if let animation = context.transaction.newAnimation(at: context.currentFrameTime) {
            self.animate(to: value, animation: animation)
        } else {
            self.setValue(value)
        }

        return isAnimating && !wasAnimating
    }
}
