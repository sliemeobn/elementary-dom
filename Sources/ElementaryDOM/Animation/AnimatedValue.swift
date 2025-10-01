private struct RunningAnimation {
    let trackedInstance: AnimationTracker.Instance?
    let animation: Animation
    let startTime: Double
    let target: AnimatableVector
    var context: AnimationContext
    var hasLogicallyCompleted: Bool = false

    mutating func animate(time: Double, additionalVector: AnimatableVector?, dryRun: Bool = false) -> AnimatableVector? {
        let result: AnimatableVector?
        if let additionalVector {
            result = animation.animate(value: target + additionalVector, time: time - startTime, context: &context)
        } else {
            result = animation.animate(value: target, time: time - startTime, context: &context)
        }

        if !dryRun && !hasLogicallyCompleted && context.isLogicallyComplete {
            trackedInstance?.reportLogicallyComplete()
            hasLogicallyCompleted = true
        }

        return result
    }

    mutating func reportRemoved() {
        // TODO: maybe make this non-copyable and have a consuming remove func
        trackedInstance?.reportRemoved()
    }
}

struct AnimatedValue<Value: AnimatableVectorConvertible>: ~Copyable {
    private var runningAnimations: [RunningAnimation] = []
    private var currentTarget: Value
    private var currentAnimationValue: Value

    private var animationBase: AnimatableVector

    var model: Value { borrowing get { currentTarget } }
    var presentation: Value { borrowing get { currentAnimationValue } }
    var isAnimating: Bool { borrowing get { !runningAnimations.isEmpty } }

    init(value: Value) {
        self.animationBase = value.animatableVector
        self.currentTarget = value
        self.currentAnimationValue = value
    }

    mutating func setValue(_ value: Value) {
        self.animationBase = value.animatableVector
        self.currentTarget = value
        self.currentAnimationValue = value

        removeAnimations(upThrough: runningAnimations.endIndex - 1, skipBaseUpdate: true)
    }

    mutating func cancelAnimation() {
        guard isAnimating else { return }

        // setting value cancels all animations
        setValue(currentTarget)
    }

    mutating func animate(to value: Value, startTime: Double, animation: Animation, tracker: AnimationTracker? = nil) {

        self.progressToTime(startTime)
        var animationTarget = value.animatableVector - currentTarget.animatableVector
        var context = AnimationContext()

        if let previous = runningAnimations.last {
            var previousContext = previous.context
            let elapsedTime = startTime - previous.startTime
            let shouldMerge = animation.shouldMerge(
                previous: previous.animation,
                value: previous.target,
                time: elapsedTime,
                context: &previousContext
            )

            if shouldMerge {
                self.animationBase = currentAnimationValue.animatableVector
                self.removeAnimations(upThrough: runningAnimations.endIndex - 1, skipBaseUpdate: true)
                animationTarget = value.animatableVector - self.animationBase
                context = previousContext
                // FIXME: this feels very hacky....
                context.isLogicallyComplete = false
            }
        }

        self.currentTarget = value
        runningAnimations.append(
            RunningAnimation(
                trackedInstance: tracker?.addAnimation(),
                animation: animation,
                startTime: startTime,
                target: animationTarget,
                context: context
            )
        )
    }

    mutating func progressToTime(_ time: Double) {
        guard isAnimating else { return }

        let (animatedVector, finishedAnimationIndex) = calculateAnimationAtTime(
            time,
            runningAnimations: &runningAnimations[...],
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
        var runningAnimations = runningAnimations[...]
        var base = animationBase

        results.reserveCapacity(times.underestimatedCount)

        for time in times {
            let (animatedVector, completedIndex) = calculateAnimationAtTime(
                time,
                runningAnimations: &runningAnimations,
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
            runningAnimations[i].trackedInstance?.reportRemoved()
            if !skipBaseUpdate {
                self.animationBase += runningAnimations[i].target
            }
        }
        runningAnimations.removeSubrange(0...index)
    }

    deinit {
        if isAnimating {
            logWarning("AnimatedValue deinit with running animations")
        }
    }
}

private func calculateAnimationAtTime(
    _ time: Double,
    runningAnimations: inout ArraySlice<RunningAnimation>,
    dryRun: Bool = false
) -> (animatedVector: AnimatableVector, finishedAnimationIndex: Int?) {
    guard runningAnimations.count > 1 else {
        assert(runningAnimations.first != nil, "Running animations should not be empty")
        if let vector = runningAnimations[0].animate(time: time, additionalVector: nil) {
            return (vector, nil)
        } else {
            return (runningAnimations[0].target, runningAnimations.indices.first)
        }
    }

    var finishedAnimationIndex: Int?
    var index = runningAnimations.startIndex

    let zero = AnimatableVector.zero(runningAnimations.first!.target)

    var totalAnimationVector = zero
    var carryOverVector = zero

    while index < runningAnimations.endIndex {
        if let vector = runningAnimations[index].animate(time: time, additionalVector: carryOverVector, dryRun: dryRun) {
            totalAnimationVector += vector
            carryOverVector = runningAnimations[index].target - vector
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

        if !context.transaction.disablesAnimation,
            let animation = context.transaction.animation
        {
            self.animate(
                to: value,
                startTime: context.currentFrameTime,
                animation: animation,
                tracker: context.transaction._animationTracker
            )
        } else {
            self.setValue(value)
        }

        return isAnimating && !wasAnimating
    }
}
