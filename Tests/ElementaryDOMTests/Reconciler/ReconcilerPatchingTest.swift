import ElementaryDOM
import Testing

struct ReconcilerPatchingTests {
    @Test
    func patchesText() {
        let state = ToggleState()
        let ops = patchOps {
            HTMLText("\(state.value)")
        } toggle: {
            state.toggle()
        }

        #expect(ops == [.patchText(node: "false", to: "true")])
    }

    @Test
    func patchesFragmentAndNodes() {
        let state = ToggleState()
        let ops = patchOps {
            div {
                p(.id("\(state.value)")) {}
                a {}.attributes(.hidden, when: !state.value)
            }
        } toggle: {
            state.toggle()
        }

        #expect(
            ops == [
                .setAttr(node: "<p>", name: "id", value: "true"),
                .removeAttr(node: "<a>", name: "hidden"),
            ]
        )
    }

    @Test func patchesOptionals() async throws {
        let state = ToggleState()
        let ops = patchOps {
            div {
                if state.value {
                    p {}
                }
                a {}
                if !state.value {
                    br()
                }
            }
        } toggle: {
            state.toggle()
        }

        #expect(
            ops == [
                .createElement("p"),
                .removeChild(parent: "<div>", child: "<br>"),
                .addChild(parent: "<div>", child: "<p>", before: "<a>"),
            ]
        )
    }

    @Test func patchesConditionals() async throws {
        let state = ToggleState()
        let ops = patchOps {
            div {
                if state.value {
                    p {}
                } else {
                    a {}
                }
            }
        } toggle: {
            state.toggle()
        }

        #expect(
            ops == [
                .createElement("p"),
                .removeChild(parent: "<div>", child: "<a>"),
                .addChild(parent: "<div>", child: "<p>"),
            ]
        )
    }

    @Test func patchesSwitch() async throws {
        let state = CounterState()
        let ops = patchOps {
            div {}
            switch state.number {
            case 0:
                p {}
            case 1:
                a {}
            default:
                br()
            }
            img()
        } toggle: {
            state.number += 1
        }

        #expect(
            ops == [
                .createElement("a"),
                .addChild(parent: "<>", child: "<a>", before: "<img>"),
                .removeChild(parent: "<>", child: "<p>"),
            ]
        )
    }

    @Test func patchesSwitchMultipleTimes() async throws {
        let state = CounterState()
        let dom = TestDOM()
        dom.mount {
            div {
                switch state.number {
                case 0:
                    p {}
                case 1:
                    a {}
                default:
                    br()
                }
            }
        }
        state.number += 1
        dom.runNextFrame()
        dom.clearOps()

        state.number += 1
        dom.runNextFrame()

        #expect(
            dom.ops == [
                .createElement("br"),
                .addChild(parent: "<div>", child: "<br>"),
                .removeChild(parent: "<div>", child: "<a>"),
            ]
        )
    }

    // TODO: add tests for lists (growing, shrinking, no-change)
    // TODO: add tests for keyed lists (reordering, adding, removing in the middle)

    @Test
    func countsUp() {
        let state = CounterState()

        let dom = TestDOM()
        dom.mount {
            p { "\(state.number)" }
        }
        dom.clearOps()

        state.number += 1
        dom.runNextFrame()

        #expect(!dom.hasWorkScheduled)

        state.number += 1
        state.number += 1
        dom.runNextFrame()

        #expect(
            dom.ops == [
                .patchText(node: "0", to: "1"),
                .patchText(node: "1", to: "3"),
            ]
        )
        #expect(!dom.hasWorkScheduled)
    }
}

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
