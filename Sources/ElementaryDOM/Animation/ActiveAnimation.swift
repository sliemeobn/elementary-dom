struct RunningAnimation {
    var startTime: Double
    var target: AnimatableVector
    var animation: Animation
    var context: AnimationContext
}

struct PresentationValue<Value: AnimatableVectorConvertible> {
    var base: AnimatableVector

    var runningAnimations: [RunningAnimation] = []
    var currentTarget: AnimatableVector

    init(value: Value) {
        self.base = value.animatableVector
        self.currentTarget = base
    }

    mutating func setNewTarget(_ target: Value, _ context: borrowing _RenderContext) {
        currentTarget = target.animatableVector

        if context.transaction?.animation != nil {
            // runningAnimations.append(
            //     RunningAnimation(
            //         startTime: transaction.startTime,
            //         target: target.animatableVector,
            //         animation: transaction.animation,
            //         context: transaction.context
            //     )
        }
    }
}
