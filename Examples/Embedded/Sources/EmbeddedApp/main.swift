import ElementaryDOM
import JavaScriptKit

_ = JSObject.global.console.log("Hello from Embedded Swift")

print("Hello from Embedded Swift")

App().mount(in: JSObject.global.document.body.object!)

let state = State()

struct App: View {
    var content: some View {
        div {
            h1 { "Embedded Swift" }
            Counter()
            hr()
            TimerView(timer: state.timer)
            // if state.timer.isTimerRunning {
            //     p { "Timer is running" }
            // }
        }
    }
}

struct Counter: View {
    var content: some View {
        h2 { "Counter FOO" }
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

struct TimerView: View {
    var timer: Timer

    var content: some View {
        div {
            h2 { "Timer" }
            p {
                "Seconds: "
                span(.style("color: blue")) { "\(timer.ticks)" }
            }
            button { timer.isTimerRunning ? "Stop Timer" : "Start Timer" }
                .on("click") { _ in
                    timer.toggle()
                }
        }
    }
}

final class State {
    var count = 0 {
        willSet {
            _future_change_tracking_manual_for_now()
        }
    }

    let timer = Timer()
}

final class Timer {
    init() { print("Timer initialized") }
    deinit { print("Timer deinitialized") }

    private var timer: JSTimer? {
        willSet {
            _future_change_tracking_manual_for_now()
        }
    }

    var ticks: Int = 0 {
        willSet {
            _future_change_tracking_manual_for_now()
        }
    }

    var isTimerRunning: Bool { timer != nil }

    func toggle() {
        if timer != nil {
            timer = nil
            print("Timer stopped")
        } else {
            timer = JSTimer(millisecondsDelay: 1000, isRepeating: true) {
                self.ticks += 1
            }
            print("Timer started")
        }
    }
}
