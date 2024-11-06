import ElementaryDOM
import JavaScriptKit

@View
struct App {
    var content: some View {
        GameView()
    }
}

App().mount(in: JSObject.global.document.body.object!)

// // this should probably go in an "onMounted" closure or similar
// Document.onKeyDown { event in
//     guard let key = EnteredKey(event) else { return }
//     store.onKeyPressed(key)
// }
