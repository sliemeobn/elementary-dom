import ElementaryDOM
import Testing

@Suite
struct ViewMacroTests {
    @Test
    func testViewMacro() {
        let view = MyView(number: 2)
        let storage = MyView._initializeState(from: view)

        var view2 = MyView()
        MyView._restoreState(storage, in: &view2)
        #expect(view2.number == 2)
    }

    @Test
    func testStatelessView() {
        let view = StatelessView()
        _ = StatelessView._renderView(view, context: .empty)
    }
}

@View
struct MyView {
    @State var number = 0

    var content: some View {
        "Hello \(number)"
    }
}

@View
struct StatelessView {
    var content: some View {
        "Hello"
    }
}
