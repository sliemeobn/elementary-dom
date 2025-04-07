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
        TextField(value: #Binding(data.name))
        div {
            p { "Via Binding: \(data.name)" }
            p { TestValueView() }
            p { TestObjectView() }
        }
        .environment(#Key(\.myText), data.name)
        .environment(data)

        hr()

        ForEach(counters, key: { String($0) }) { counter in
            div {
                h3 { "Counter \(counter)" }
                Counter(count: counter)
                br()
                button { "Remove counter" }
                    .onClick { _ in
                        counters.removeAll { $0 == counter }
                    }
                hr()
            }
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
            print("Counter with count \(count) mounted")
        }
        .onUnmount {
            print("Counter with count \(count) unmounted")
        }
    }
}

@View
struct TextField {
    @Binding var value: String

    var content: some View {
        // TODO: make proper two-way binding for DOM elements
        input(.type(.text))
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
struct TestValueView {
    @Environment(#Key(\.myText)) var key

    var content: some View {
        span { "Via environment value: \(key)" }
    }
}

@View
struct TestObjectView {
    @Environment<SomeData>() var data
    // @Environment<SomeData?>() var optionalData

    var content: some View {
        span { "Via environment object: \(data.name)" }
        // TODO: figure out how to make optional environment object work in embedded
        // br()
        // span { "Via optional environment object: \(optionalData?.name ?? "")" }
    }
}
