import ElementaryDOM

extension EnvironmentValues {
    @Entry var myText = ""
}

@View
struct App {
    @State var counters: [Int] = [1]
    @State var nextCounterName = 1
    @State var data = SomeData()

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
        hr()
        TextField(value: Binding(get: { data.name }, set: { data.name = $0 }))
        div {
            p { "Via Binding: \(data.name)" }
            p { TestView() }
        }.environment(#Key(\.myText), data.name)
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

@View
struct TextField {
    @Binding var value: String

    var content: some View {
        input(.type(.text), .value("Hello"))
            .onInput { event in
                value = event.targetValue ?? ""
            }
    }
}

@Reactive
final class SomeData {
    var name: String = ""
    var age: Int = 0
}

@View
struct TestView {
    @Environment(#Key(\.myText)) var key

    var content: some View {
        span { "Via Environment: \(key)" }
    }
}
