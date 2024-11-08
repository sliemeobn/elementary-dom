@testable import ElementaryDOM
import Testing

@Suite
struct EnvionmentTests {
    @Test
    func accessesWithProperty() {
        var v = EnvironmentValues()

        #expect(v.foo == "bar")
        v.foo = "baz"
        #expect(v.foo == "baz")
    }

    @Test
    func accessesWithStorageKey() {
        var v = EnvironmentValues()

        #expect(v[EnvironmentValues._$key_foo] == "bar")
        v[EnvironmentValues._$key_foo] = "baz"
        #expect(v[EnvironmentValues._$key_foo] == "baz")
    }

    @Test
    func accessesKeyPath() {
        var v = EnvironmentValues()

        #expect(v[#Key(\.foo)] == "bar")
        v[#Key(\.foo)] = "baz"
        #expect(v[#Key(\.foo)] == "baz")
    }

    @Test
    func loadsValueInPropertyWrapper() {
        let e1 = Environment(#Key(\.bar))
        var e2 = Environment(#Key(\.bar))
        var e3 = Environment(#Key(\.bar))

        var v = EnvironmentValues()
        v.bar = 42

        e2.__load(from: EnvironmentValues())
        e3.__load(from: v)

        #expect(e1.wrappedValue == 1)
        #expect(e2.wrappedValue == 1)
        #expect(e3.wrappedValue == 42)
    }

    @Test
    func loadValuesInView() {
        var context = _ViewRenderingContext()

        var view = TestView()
        context.environment.bar = 42
        TestView.__applyContext(context, to: &view)

        #expect(view.foo == "bar")
        #expect(view.bar == 42)
    }
}

extension EnvironmentValues {
    @Entry var foo = "bar"

    @Entry var bar: Double = 1
    @Entry var somthing: Int? = nil
}

@View
private struct TestView {
    @Environment(#Key(\.foo)) var foo
    @Environment(#Key(\.bar)) var bar

    var content: some View {
        "Hello"
    }
}