import ElementaryDOM

@View
struct Counter {
    @Binding var count: Int

    var content: some View {
        div {
            button { "-" }
                .onClick { _ in count -= 1 }
            span { "\(count)" }
            button { "+" }
                .onClick { _ in count += 1 }
        }
    }
}
