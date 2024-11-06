import ElementaryDOM

@View
struct App {
    @State var counters: [Int] = [1]
    @State var nextCounterName = 1

    var content: some View {
        for (index, counter) in counters.enumerated() {
            h3 { "Counter \(counter)" }
            Counter(count: counter)
            br()
            button { "Remove counter" }
                .onClick { _ in
                    counters.remove(at: index)
                }
            hr()
        }
        button { "Add counter" }
            .onClick { _ in
                nextCounterName += 1
                counters.append(nextCounterName)
            }
    }
}

@View
struct Counter {
    @State var count: Int = 0

    var content: some View {
        div {
            button { "-" }
                .onClick { _ in count -= 1 }
            span { " \(count) " }
            button { "+" }
                .onClick { _ in count += 1 }
        }
        .onMount {
            print("Counter \(count) mounted")
        }
        .onUnmount {
            print("Counter \(count) dismounted")
        }
    }
}
