import ElementaryDOM
import Testing

struct ReconcilerUpdateTests {
    @Test
    func runsBodiesOnMount() {
        let state = State()
        let calls = trackMounting { Outer(state: state) }

        #expect(calls == ["Outer", "Inner", "value: 0"])
    }

    @Test
    func updatesEnvironmentValues() {
        let state = State()

        let calls = trackUpdating {
            Outer(state: state)
        } toggle: {
            state.envValue += 1
        }

        #expect(calls == ["Outer", "value: 1"])
    }

    @Test
    func doesNotUpdateEnvironmentValuesIfEqual() {
        let state = State()

        let calls = trackUpdating {
            Outer(state: state)
        } toggle: {
            state.toggle.toggle()
        }

        #expect(calls == ["Outer"])
    }
}

@Reactive
private class State {
    var envValue: Int = 0
    var toggle: Bool = false
}

@View
private struct Outer {
    let state: State

    var content: some View {
        Track(name: "Outer") {
            Inner()
            let _ = state.toggle
        }
        .environment(#Key(\.testValue), state.envValue)
    }
}

@View
private struct Inner {
    var content: some View {
        Track(name: "Inner") {
            ValueView()
        }
    }
}

@View
private struct ValueView {
    @Environment(#Key(\.testValue)) var value

    var content: some View {
        Track(name: "value: \(value)") {
        }
    }
}

extension EnvironmentValues {
    @Entry fileprivate var testValue: Int
}
