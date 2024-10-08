import ElementaryDOM
import JavaScriptKit

Counter().mount(in: JSObject.global.document.body.object!)

final class State {
    var count = 0 {
        willSet {
            _future_change_tracking_manual_for_now()
        }
    }
}

let state = State()

struct Counter: View {
    var content: some View {
        p(.style("color: red")) {
            b { "Count \(state.count)" }
        }
        hr()
        div {
            button { "-" }
                .on("click") { _ in
                    state.count -= 1
                }

            button { "+" }
                .on("click") { _ in
                    state.count += 1
                }
            span { " " }
            button { "Say Hello" }
                .on("click") { _ in
                    print("Hello from Embedded Swift, current state is \(state.count)")
                }
        }
    }
}
