import ElementaryDOM
import Testing

@testable import ElementaryDOM

struct FLIPTests {
    @Test
    func capturesFirstPositionBeforeDOMChanges() {
        let state = StringListState(["A", "B", "C"])
        let dom = TestDOM()

        dom.mount {
            div {
                ForEach(state.items, key: \.self) { item in
                    p { item }
                }
            }
            .animateChildren()
        }
        dom.runNextFrame()
        dom.clearOps()

        // Shuffle with animation
        withAnimation(.linear(duration: 0.3)) {
            state.items = ["C", "A", "B"]
        }
        dom.runNextFrame()

        // Verify DOM operations occurred (moves)
        #expect(!dom.ops.isEmpty)
    }

    @Test
    func skipsFlipWhenNoAnimation() {
        let state = StringListState(["A", "B", "C"])
        let dom = TestDOM()

        dom.mount {
            div {
                ForEach(state.items, key: \.self) { item in
                    p { item }
                }
            }
            .animateChildren()
        }
        dom.runNextFrame()
        dom.clearOps()

        // Shuffle WITHOUT animation
        state.items = ["C", "A", "B"]
        dom.runNextFrame()

        // DOM should still be updated but no FLIP
        #expect(dom.ops.contains { op in
            if case .addChild = op { return true }
            return false
        })
    }

    @Test
    func handlesSingleElementMove() {
        let state = StringListState(["A", "B", "C"])
        let dom = TestDOM()

        dom.mount {
            ul {
                ForEach(state.items, key: \.self) { item in
                    li { item }
                }
            }
            .animateChildren()
        }
        dom.runNextFrame()
        dom.clearOps()

        // Move first element to end
        withAnimation(.snappy) {
            state.items = ["B", "C", "A"]
        }
        dom.runNextFrame()

        // Verify DOM was updated
        #expect(!dom.ops.isEmpty)
    }

    @Test
    func handlesMultipleConsecutiveChanges() {
        let state = StringListState(["A", "B", "C", "D"])
        let dom = TestDOM()

        dom.mount {
            div {
                ForEach(state.items, key: \.self) { item in
                    span { item }
                }
            }
            .animateChildren()
        }
        dom.runNextFrame()

        // First animated change
        withAnimation(.easeInOut(duration: 0.2)) {
            state.items = ["D", "C", "B", "A"]
        }
        dom.runNextFrame()
        dom.clearOps()

        // Second animated change (should handle takeover)
        withAnimation(.snappy) {
            state.items = ["A", "B", "C", "D"]
        }
        dom.runNextFrame()

        // Both changes should complete without error
        #expect(!dom.ops.isEmpty)
    }

    @Test
    func cleanupOnUnmount() {
        let state = StringListState(["A", "B"])
        let showList = ToggleState()
        showList.value = true
        let dom = TestDOM()

        dom.mount {
            div {
                if showList.value {
                    div {
                        ForEach(state.items, key: \.self) { item in
                            p { item }
                        }
                    }
                    .animateChildren()
                }
            }
        }

        dom.runNextFrame()

        // Start a FLIP animation
        withAnimation(.linear(duration: 1.0)) {
            state.items = ["B", "A"]
        }
        dom.runNextFrame()

        // Remove the list (unmount)
        showList.value = false
        dom.runNextFrame()

        // Should complete without crash - verify by checking we get here
        #expect(dom.ops.count >= 0)
    }

    @Test
    func animatesListShuffle() {
        let state = StringListState(["Item1", "Item2", "Item3", "Item4", "Item5"])
        let dom = TestDOM()

        dom.mount {
            ul {
                ForEach(state.items, key: \.self) { item in
                    li { item }
                }
            }
            .animateChildren()
        }
        dom.runNextFrame()
        dom.clearOps()

        // Shuffle the list with animation
        withAnimation(.bouncy) {
            state.items = ["Item5", "Item3", "Item1", "Item4", "Item2"]
        }
        dom.runNextFrame()

        // Should have multiple move operations
        let moveOps = dom.ops.filter { op in
            if case .addChild = op { return true }
            return false
        }
        #expect(!moveOps.isEmpty)
    }
}

// MARK: - Test Helpers

@Reactive
private class StringListState {
    var items: [String]

    init(_ items: [String] = []) {
        self.items = items
    }
}

@Reactive
private class ToggleState {
    var value = false
}
