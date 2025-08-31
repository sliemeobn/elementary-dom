import ElementaryDOM
import Testing

@Suite
struct ViewMacroTests {
    @Test
    func viewMacro() {
        let view = MyView(number: 2)
        let storage = MyView.__initializeState(from: view)

        var view2 = MyView()
        MyView.__restoreState(storage, in: &view2)
        #expect(view2.number == 2)
    }

    // @Test
    // func statelessView() {
    //     let view = StatelessView()
    //     StatelessView._makeNode(view, context: .empty, reconciler: _ReconcilerBatch)
    // }
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
