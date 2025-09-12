import ElementaryDOM

@View
struct App {
    var content: some View {
        GameView()
    }
}

print("Mounting app")
App().mount(in: .body)
