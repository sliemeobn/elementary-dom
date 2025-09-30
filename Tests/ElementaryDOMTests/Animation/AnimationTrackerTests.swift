import Testing

@testable import ElementaryDOM

@Suite
struct AnimationTrackerTests {
    @Test
    func runsCompletionCallbacksWhenAllLogicallyComplete() {
        let tracker = AnimationTracker()
        var completionCount = 0

        tracker.addAnimationCompletion(criteria: .logicallyComplete) {
            completionCount += 1
        }

        let id = tracker.addAnimation()
        tracker.reportLogicallyComplete(id)

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

        let id = tracker.addAnimation()
        tracker.reportRemoved(id)

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

        let id1 = tracker.addAnimation()
        let id2 = tracker.addAnimation()

        tracker.reportLogicallyComplete(id1)
        #expect(completionCount == 0)
        #expect(removalCount == 0)

        tracker.reportLogicallyComplete(id2)
        #expect(completionCount == 1)
        #expect(removalCount == 0)

        tracker.reportRemoved(id1)
        #expect(removalCount == 0)

        tracker.reportRemoved(id2)
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

        let id = tracker.addAnimation()
        tracker.reportRemoved(id)

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
