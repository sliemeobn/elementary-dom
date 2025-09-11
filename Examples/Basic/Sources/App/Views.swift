import ElementaryDOM

extension EnvironmentValues {
    @Entry var myText: String = ""
}

@View
struct App {
    @State var counters: [Int] = [1]
    @State var nextCounterName = 1
    @State var data = SomeData()

    var content: some View {
        div {
            TextField(value: #Binding(data.name))

            div {
                p { "Via Binding: \(data.name)" }
                p { TestValueView() }
                p { TestObjectView() }
            }
            .environment(#Key(\.myText), data.name)
            .environment(data)
        }
        hr()
        BindingsView()
        hr()
        // TODE: replaceChildren does not keep animations and similar going....
        // if counters.count > 1 {
        //     span {}.attributes(.style(["display": "none"]))
        // }

        p {
            switch counters.count {
            case 0:
                "No counters"
            case 1:
                "One counter"
            default:
                "Multiple counters"
            }
        }
        .attributes(
            .style([
                "transition": "all 1s",
                "color": counters.count > 1 ? "red" : "blue",
            ])
        )

        div {
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
    @Binding<String> var value: String

    var content: some View {
        input(.type(.text))
            .bindValue($value)
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
    @Environment(SomeData.self) var data: SomeData
    @Environment(SomeData.self) var optionalData: SomeData?

    var content: some View {
        span { "Via environment object: \(data.name)" }
        // TODO: figure out how to make optional environment object work in embedded
        br()
        //span { "Via optional environment object: \(optionalData?.name ?? "")" }
    }
}
