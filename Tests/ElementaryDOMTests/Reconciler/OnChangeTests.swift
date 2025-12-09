import ElementaryDOM
import Reactivity
import Testing

@MainActor
@Suite
struct OnChangeTests {
    @Test
    func callsOnChangeWhenValueChanges() {
        var changeCount = 0
        let state = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) {
                    changeCount += 1
                }
        } toggle: {
            state.number = 1
        }

        #expect(changeCount == 1)
    }

    @Test
    func doesNotCallOnChangeWhenValueStaysSame() {
        var changeCount = 0
        let state = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) {
                    changeCount += 1
                }
        } toggle: {
            state.number = 0  // Same value
        }

        #expect(changeCount == 0)
    }

    @Test
    func callsOnChangeWithInitialWhenMounted() {
        var changeCount = 0

        _ = mountOps {
            div {}
                .onChange(of: 42, initial: true) {
                    changeCount += 1
                }
        }

        #expect(changeCount == 1)
    }

    @Test
    func doesNotCallOnChangeWithoutInitialWhenMounted() {
        var changeCount = 0

        _ = mountOps {
            div {}
                .onChange(of: 42, initial: false) {
                    changeCount += 1
                }
        }

        #expect(changeCount == 0)
    }

    @Test
    func callsOnChangeWithOldAndNewValues() {
        var capturedOld: Int?
        var capturedNew: Int?
        let state = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) { oldValue, newValue in
                    capturedOld = oldValue
                    capturedNew = newValue
                }
        } toggle: {
            state.number = 5
        }

        #expect(capturedOld == 0)
        #expect(capturedNew == 5)
    }

    @Test
    func callsOnChangeWithInitialValueForBothParameters() {
        var capturedOld: Int?
        var capturedNew: Int?
        let state = CounterState()
        state.number = 42

        _ = mountOps {
            div {}
                .onChange(of: state.number, initial: true) { oldValue, newValue in
                    capturedOld = oldValue
                    capturedNew = newValue
                }
        }

        #expect(capturedOld == 42)
        #expect(capturedNew == 42)
    }

    @Test
    func callsMultipleOnChangeHandlers() {
        var firstHandlerCount = 0
        var secondHandlerCount = 0
        let state = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) {
                    firstHandlerCount += 1
                }
                .onChange(of: state.number) {
                    secondHandlerCount += 1
                }
        } toggle: {
            state.number = 1
        }

        #expect(firstHandlerCount == 1)
        #expect(secondHandlerCount == 1)
    }

    @Test
    func callsCorrectOnChangeHandler() {
        var firstHandlerCount = 0
        var secondHandlerCount = 0
        let state = CounterState()
        let state2 = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) {
                    firstHandlerCount += 1
                }
                .onChange(of: state2.number) {
                    secondHandlerCount += 1
                }
        } toggle: {
            state.number = 1
        }

        #expect(firstHandlerCount == 1)
        #expect(secondHandlerCount == 0)
    }

    @Test
    func callsOnChangeMultipleTimesForMultipleChanges() {
        nonisolated(unsafe) var changeCount = 0
        let state = CounterState()

        _ = patchOps {
            div {}
                .onChange(of: state.number) {
                    changeCount += 1
                }
        } toggle: {
            state.number = 1
            // force two separate transaction
            withAnimation {
                state.number = 2
            }
        }

        #expect(changeCount == 2)
    }
}

// MARK: - Test Helper Classes

@Reactive
private class CounterState {
    var number = 0
}
