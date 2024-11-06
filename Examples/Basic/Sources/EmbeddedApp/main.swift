import ElementaryDOM
import JavaScriptKit

@View
struct App {
    @State var text = ""
    @State var count = 0

    var content: some View {
        Counter(count: $count)
    }
}

App().mount(in: JSObject.global.document.body.object!)
