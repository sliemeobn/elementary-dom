import Testing

@testable import ElementaryUI

@Suite
struct AnimationTrackerTests {
    @Test
    func runsCompletionCallbacksWhenAllLogicallyComplete() {
        let tracker = AnimationTracker()
        var completionCount = 0

        tracker.addAnimationCompletion(criteria: .logicallyComplete) {
            completionCount += 1
        }

        let instance = tracker.addAnimation()
        instance.reportLogicallyComplete()

        #expect(completionCount == 1)
        #expect(tracker.areAllCallbacksRun)
    }

    @Test
    func runsRemovalCallbacksWhenAllRemoved() {
        let tracker = AnimationTracker()
        var removalCount = 0

        tracker.addAnimationCompletion(criteria: .removed) {
            removalCount += 1
        }

        let instance = tracker.addAnimation()
        instance.reportRemoved()

        #expect(removalCount == 1)
        #expect(tracker.areAllCallbacksRun)
    }

    @Test
    func callbacksDoNotRunPrematurelyWithMultipleAnimations() {
        let tracker = AnimationTracker()
        var completionCount = 0
        var removalCount = 0

        tracker.addAnimationCompletion(criteria: .logicallyComplete) {
            completionCount += 1
        }
        tracker.addAnimationCompletion(criteria: .removed) {
            removalCount += 1
        }

        let instance1 = tracker.addAnimation()
        let instance2 = tracker.addAnimation()

        instance1.reportLogicallyComplete()
        #expect(completionCount == 0)
        #expect(removalCount == 0)

        instance2.reportLogicallyComplete()
        #expect(completionCount == 1)
        #expect(removalCount == 0)

        instance1.reportRemoved()
        #expect(removalCount == 0)

        instance2.reportRemoved()
        #expect(removalCount == 1)
        #expect(tracker.areAllCallbacksRun)
    }

    @Test
    func completionRunsBeforeRemovalWhenRemovedFirst() {
        let tracker = AnimationTracker()
        var order: [String] = []

        tracker.addAnimationCompletion(criteria: .logicallyComplete) {
            order.append("C")
        }
        tracker.addAnimationCompletion(criteria: .removed) {
            order.append("R")
        }

        let instance = tracker.addAnimation()
        instance.reportRemoved()

        #expect(order == ["C", "R"])
        #expect(tracker.areAllCallbacksRun)
    }

    @Test
    func deinitRunsPendingCallbacks() {
        var completionCount = 0
        var removalCount = 0

        do {
            var tracker: AnimationTracker? = AnimationTracker()
            tracker!.addAnimationCompletion(criteria: .logicallyComplete) {
                completionCount += 1
            }
            tracker!.addAnimationCompletion(criteria: .removed) {
                removalCount += 1
            }
            tracker = nil
        }

        #expect(completionCount == 1)
        #expect(removalCount == 1)
    }
}
