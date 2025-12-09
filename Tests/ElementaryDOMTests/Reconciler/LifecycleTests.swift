import ElementaryDOM
import Reactivity
import Testing

// TODO: revisit this with main actor stuff (if possible in embedded)
@MainActor
struct LifecycleTests {
    @Test
    func callsOnMountWhenElementIsMounted() {
        var mountCount = 0
        _ = mountOps {
            div {}
                .onMount {
                    mountCount += 1
                }
        }

        #expect(mountCount == 1)
    }

    @Test
    func callsOnMountForMultipleElements() {
        var mountCount = 0
        _ = mountOps {
            div {
                p {}.onMount { mountCount += 1 }
                span {}.onMount { mountCount += 1 }
            }.onMount { mountCount += 1 }
        }

        #expect(mountCount == 3)
    }

    @Test
    func callsOnMountForConditionalElements() {
        var mountCount = 0
        let state = ToggleState()
        _ = patchOps {
            div {
                if state.value {
                    p {}.onMount {
                        mountCount += 1
                    }
                }
            }
        } toggle: {
            state.toggle()
        }

        #expect(mountCount == 1)
    }

    @Test
    func callsOnMountMultipleTimesForNestedLifecycleEvents() {
        var mountCount = 0
        _ = mountOps {
            div {}
                .onMount { mountCount += 1 }
                .onMount { mountCount += 1 }
        }

        #expect(mountCount == 2)
    }

    // MARK: - onUnmount Tests

    @Test
    func callsOnUnmountWhenElementIsUnmounted() {
        var unmountCount = 0
        let state = ToggleState()
        state.toggle()

        _ = patchOps {
            div {
                if state.value {
                    p {}.onUnmount {
                        unmountCount += 1
                    }
                }
            }
        } toggle: {
            state.toggle()
        }

        #expect(unmountCount == 1)
    }

    @Test
    func callsOnUnmountForMultipleElements() {
        var unmountCount = 0
        let state = ToggleState()
        state.toggle()

        _ = patchOps {
            if state.value {
                div {
                    p {}.onUnmount { unmountCount += 1 }
                    span {}.onUnmount { unmountCount += 1 }
                }.onUnmount { unmountCount += 1 }
            }
        } toggle: {
            state.toggle()
        }

        #expect(unmountCount == 3)
    }

    @Test
    func callsOnUnmountForKeyedElements() {
        nonisolated(unsafe) var unmountCount = 0
        let state = StringListState(["A", "B"])

        _ = patchOps {
            ForEach(state.items, key: \.self) { item in
                p { item }.onUnmount {
                    if item == "A" {
                        unmountCount += 1
                    }
                }
            }
        } toggle: {
            state.items.removeFirst()  // Remove "A"
        }

        #expect(unmountCount == 1)
    }

    // MARK: - task Tests

    @Test
    func executesTaskOnMount() async {
        let taskStream = AsyncStream<Void> { continuation in
            _ = mountOps {
                div {}
                    .task {
                        continuation.yield(())
                        continuation.finish()
                    }
            }
        }

        var count = 0
        for await _ in taskStream {
            count += 1
        }

        #expect(count == 1)
    }

    @Test
    func cancelsTaskOnUnmount() async {
        let taskStream = AsyncStream<Void> { continuation in
            let state = ToggleState()
            state.toggle()

            _ = patchOps {
                div {
                    if state.value {
                        p {}.task {
                            try? await Task.sleep(for: .seconds(10000))
                            continuation.yield(())
                            continuation.finish()
                        }
                    }
                }
            } toggle: {
                state.toggle()
            }
        }

        var count = 0
        for await _ in taskStream {
            count += 1
        }

        #expect(count == 1)
    }

    @Test
    func executesMultipleTasksIndependently() async {
        let taskStream = AsyncStream<Int> { continuation in
            var taskCount = 0

            _ = mountOps {
                div {
                    p {}.task {
                        taskCount += 1
                        continuation.yield(taskCount)
                        if taskCount == 2 {
                            continuation.finish()
                        }
                    }
                    span {}.task {
                        taskCount += 1
                        continuation.yield(taskCount)
                        if taskCount == 2 {
                            continuation.finish()
                        }
                    }
                }
            }
        }

        var finalCount = 0
        for await count in taskStream {
            finalCount = count
        }

        #expect(finalCount == 2)
    }

    // MARK: - Combined Lifecycle Tests

    @Test
    func combinesOnMountAndOnUnmount() {
        var mountCount = 0
        var unmountCount = 0
        let state = ToggleState()
        state.toggle()  // Start with true

        _ = patchOps {
            div {
                if state.value {
                    p {}
                        .onMount { mountCount += 1 }
                        .onUnmount { unmountCount += 1 }
                }
            }
        } toggle: {
            state.toggle()  // Change to false to trigger unmount
        }

        #expect(mountCount == 1)  // Element was mounted during initial mount
        #expect(unmountCount == 1)  // Element was unmounted during patch
    }

    @Test
    func handlesLifecycleEventsInForEach() {
        nonisolated(unsafe) var mountCount = 0
        let items = ["A", "B", "C"]

        _ = mountOps {
            ForEach(items, key: \.self) { item in
                p { item }.onMount { mountCount += 1 }
            }
        }

        #expect(mountCount == 3)
    }

    @Test
    func handlesLifecycleEventsWithStateChanges() {
        nonisolated(unsafe) var mountCount = 0
        nonisolated(unsafe) var unmountCount = 0
        let state = CounterState()

        _ = patchOps {
            ForEach(0..<state.number, key: \.self) { i in
                p { "\(i)" }
                    .onMount { mountCount += 1 }
                    .onUnmount { unmountCount += 1 }
            }
        } toggle: {
            state.number = 2  // Add 2 items
            state.number = 1  // Remove 1 item
        }

        #expect(mountCount == 1)  // Only 1 item remains mounted at the end
        #expect(unmountCount == 0)  // No items were unmounted (the final state has 1 item)
    }

    @Test
    func doesNotCallOnMountForExistingElements() {
        nonisolated(unsafe) var mountCount = 0
        let state = ToggleState()
        state.toggle()  // Start with true

        _ = patchOps {
            div {
                p {}.onMount { mountCount += 1 }
                if state.value {
                    span {}  // This doesn't have onMount, so adding it shouldn't trigger existing onMount
                }
            }
        } toggle: {
            state.toggle()  // Just changes the conditional, doesn't remount the p
        }

        #expect(mountCount == 1)  // onMount was called during initial mount when p was created
    }

    @Test
    func callsOnUnmountMultipleTimesForNestedLifecycleEvents() {
        nonisolated(unsafe) var unmountCount = 0
        let state = ToggleState()
        state.toggle()  // Start with true

        _ = patchOps {
            if state.value {
                div {}
                    .onUnmount { unmountCount += 1 }
                    .onUnmount { unmountCount += 1 }
            }
        } toggle: {
            state.toggle()
        }

        #expect(unmountCount == 2)
    }
}

// MARK: - Test Helper Classes

@Reactive
private class ToggleState {
    var value = false

    func toggle() {
        value.toggle()
    }
}

@Reactive
private class CounterState {
    var number = 0
}

@Reactive
private class StringListState {
    var items: [String]

    init(_ items: [String] = []) {
        self.items = items
    }
}
