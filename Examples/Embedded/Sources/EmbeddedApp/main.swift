import ElementaryDOM
import JavaScriptKit

@Reactive
final class GameStore {
    private(set) var game: Game

    init() {
        game = Game()
    }

    func onKeyPressed(_ key: EnteredKey) {
        game.handleKey(key)
    }

    func onRestart() {
        game = Game()
    }
}

let store = GameStore()

struct App: View {
    // game should be a @State property

    var content: some View {
        GameView(
            game: store.game,
            onKeyPressed: store.onKeyPressed,
            onRestart: store.onRestart
        )
    }
}

App().mount(in: JSObject.global.document.body.object!)

// this should probably go in an "onMounted" closure or similar
Document.onKeyDown { event in
    guard let key = EnteredKey(event) else { return }
    store.onKeyPressed(key)
}
