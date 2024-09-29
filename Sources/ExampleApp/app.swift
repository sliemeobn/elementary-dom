import ElementaryDOM
import JavaScriptEventLoop
import JavaScriptKit
import Observation

@main
@MainActor
struct App {
    static func main() {
        JavaScriptEventLoop.installGlobalExecutor()

        Test().mount(in: JSObject.global.document.body.object!)
    }
}

@MainActor
struct Test: @preconcurrency View {
    // this needs to be replaced by some @State system to store state objects (I am thinking macro generated)
    @Observable
    final class MyData {
        var count = 0
        var text = ""
    }

    var data: MyData = .init()

    var content: some View {
        div(.style("color:green")) {
            div {
                Counter(
                    count: data.count,
                    onUp: { data.count += 1 },
                    onDown: { data.count -= 1 }
                )
                if data.count > 3 {
                    small { "Count is greater than 3" }
                }
                br()
                hr()
                div {
                    input(.type(.text), .value(data.text))
                        .on("input") { o in
                            let o = o as! JSObject
                            data.text = o.target.object!.value.string!
                        }
                }
                p {
                    if data.text.isEmpty {
                        "No text entered FOO"
                    } else {
                        "Entered text: "
                        b { data.text }
                    }
                }
            }
        }
    }
}

@MainActor
struct Counter: @preconcurrency View {
    var count: Int
    var onUp: () -> Void
    var onDown: () -> Void

    var content: some View {
        div(.style("color:red; font-size: 2em")) {
            span { "Count: \(count)" }
            div {
                button { "-" }
                    .on("click") { _ in
                        onDown()
                    }
                button { "+" }
                    .on("click") { _ in
                        onUp()
                    }
            }
        }
    }
}
