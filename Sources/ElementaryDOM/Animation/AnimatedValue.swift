struct AnimationInstance {
    let startTime: Double
    let animation: Animation
    let onComplete: (() -> Void)? = nil
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
        guard value != currentTarget else { return }

        self.animationBase = value.animatableVector
        self.currentTarget = value
        self.currentAnimationValue = value

        self.runningAnimations.removeAll()  // TODO: run callbacks
    }

    mutating func animate(to value: Value, animation: AnimationInstance) {
        guard value != currentTarget else { return }

        var animationTarget = value.animatableVector - currentTarget.animatableVector

        if let previous = runningAnimations.last {
            let shouldMerge = animation.animation.shouldMerge(
                previous: previous.instance.animation,
                value: previous.target,
                time: animation.startTime,
                context: &context
            )

            if shouldMerge {
                self.animationBase = currentAnimationValue.animatableVector
                self.removeAnimations(upThrough: runningAnimations.endIndex - 1)
                animationTarget = value.animatableVector - currentAnimationValue.animatableVector
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
            context: &context,
            animationBase: &animationBase
        )

        if let finishedAnimationIndex {
            removeAnimations(upThrough: finishedAnimationIndex)
        }

        if let animatedVector {
            self.currentAnimationValue = Value(animationBase + animatedVector)
        } else {
            assert(!isAnimating)
            self.currentAnimationValue = self.currentTarget
        }
    }

    // TODO: figure out the shape for this
    func peekFutureValues(_ times: StrideThrough<Double>) -> [Value] {
        var results: [Value] = []
        var contextCopy = context
        var baseCopy = animationBase
        var runningAnimations = runningAnimations[...]

        results.reserveCapacity(times.underestimatedCount)

        for time in times {
            let (animatedVector, completedIndex) = calculateAnimationAtTime(
                time,
                runningAnimations: runningAnimations,
                context: &contextCopy,
                animationBase: &baseCopy
            )
            if let animatedVector {
                results.append(Value(baseCopy + animatedVector))
            } else {
                results.append(self.currentTarget)
            }

            if let completedIndex {
                runningAnimations = runningAnimations[(completedIndex + 1)...]
            }
        }
        return results
    }

    private mutating func removeAnimations(upThrough index: Int) {
        runningAnimations.removeSubrange(0...index)
        // TODO: run callbacks
    }
}

private func calculateAnimationAtTime<AnimationList>(
    _ time: Double,
    runningAnimations: AnimationList,
    context: inout AnimationContext,
    animationBase: inout AnimatableVector
) -> (animatedVector: AnimatableVector?, finishedAnimationIndex: AnimationList.Index?)
where AnimationList: Collection<RunningAnimation> {
    var animatedVector: AnimatableVector?
    var additionalVector: AnimatableVector?
    var finishedAnimationIndex: AnimationList.Index?
    var index = runningAnimations.startIndex

    while index < runningAnimations.endIndex {
        let runningAnimation = runningAnimations[index]

        if let vector = runningAnimation.animate(time: time, context: &context, additionalVector: additionalVector) {
            animatedVector = vector
        } else {
            finishedAnimationIndex = index
            animationBase += runningAnimation.target
            animatedVector = nil
        }

        runningAnimations.formIndex(after: &index)
        guard index < runningAnimations.endIndex else { break }

        additionalVector = animatedVector.map { runningAnimations[index].target - $0 } ?? nil
    }

    return (animatedVector, finishedAnimationIndex)
}
