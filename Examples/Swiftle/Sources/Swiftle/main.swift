import ElementaryDOM

@View
struct App {
    var body: some View {
        GameView()
    }
}

print("Mounting app")
App().mount(in: .body)
