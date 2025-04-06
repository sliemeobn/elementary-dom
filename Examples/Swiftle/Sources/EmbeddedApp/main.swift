import ElementaryDOM
import JavaScriptKit

@View
struct App {
    var content: some View {
        GameView()
    }
}

App().mount(in: .body)
