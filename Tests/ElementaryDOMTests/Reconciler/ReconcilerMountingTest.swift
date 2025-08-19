import ElementaryDOM
import Testing

struct ReconcilerMountingTests {
    @Test
    func mountsAnElement() {
        let ops = mountOps { div { "Hello" } }

        #expect(
            ops == [
                .createElement("div"),
                .createText("Hello"),
                .addChild(parent: "<div>", child: "Hello"),
                .addChild(parent: "<>", child: "<div>"),
            ]
        )
    }   

    @Test
    func setsAttributes() {
        let ops = mountOps { img(.id("foo"), .src("bar")) }

        #expect(
            ops == [
                .createElement("img"),
                .setAttr(node: "<img>", name: "id", value: "foo"),
                .setAttr(node: "<img>", name: "src", value: "bar"),
                .addChild(parent: "<>", child: "<img>"),
            ]
        )
    }

    @Test
    func setsEventListeners() {
        let ops = mountOps { button {}.onClick { _ in } }

        #expect(
            ops == [
                .createElement("button"),
                .addListener(node: "<button>", event: "click"),
                .addChild(parent: "<>", child: "<button>"),
            ]
        )
    }

    @Test
    func mountsFragment() {
        let ops = mountOps {
            ul {
                li { "Text" }
                li { p {} }
            }
        }

        #expect(
            ops == [
                .createElement("ul"),
                .createElement("li"),
                .createText("Text"),
                .createElement("li"),
                .createElement("p"),
                .addChild(parent: "<li>", child: "<p>"),
                .addChild(parent: "<li>", child: "Text"),
                .setChildren(parent: "<ul>", children: ["<li>", "<li>"]),
                .addChild(parent: "<>", child: "<ul>"),
            ]
        )
    }

    @Test
    func mountsDynamicList() {
        #expect(
            mountOps {
                div {
                    for _ in 0..<2 {
                        p {}
                    }
                }
            } == [
                .createElement("div"),
                .createElement("p"),
                .createElement("p"),
                .setChildren(parent: "<div>", children: ["<p>", "<p>"]),
                .addChild(parent: "<>", child: "<div>"),
            ]
        )
    }

    @Test
    func mountsConditionals() {
        let ops = mountOps {
            div {
                if false {
                    p {}
                } else {
                    if true {
                        a {}
                    }
                }
            }
        }

        #expect(
            ops == [
                .createElement("div"),
                .createElement("a"),
                .addChild(parent: "<div>", child: "<a>"),
                .addChild(parent: "<>", child: "<div>"),
            ]
        )
    }

    @Test
    func mountsSwitch() {
        #expect(
            mountOps {
                switch 2 {
                case 0:
                    p { "Zero" }
                case 1:
                    p { "One" }
                default:
                    p { "Two" }
                }
            } == [
                .createElement("p"),
                .createText("Two"),
                .addChild(parent: "<p>", child: "Two"),
                .addChild(parent: "<>", child: "<p>"),
            ]
        )
    }

    @Test
    func mountsStatelessFunction() {
        #expect(
            mountOps {
                TestView(text: "Hello")
            } == [
                .createElement("p"),
                .createText("Hello"),
                .addChild(parent: "<p>", child: "Hello"),
                .addChild(parent: "<>", child: "<p>"),
            ]
        )
    }

    @Test
    func mountsStatefulFunction() {
        #expect(
            mountOps {
                TestViewWithState()
            } == [
                .createElement("p"),
                .createText("12"),
                .addChild(parent: "<p>", child: "12"),
                .addChild(parent: "<>", child: "<p>"),
            ]
        )
    }
}

@View
private struct TestView {
    var text: String
    var content: some View {
        p { text }
    }
}

@View
private struct TestViewWithState {
    @State var number = 12
    var content: some View {
        p { "\(number)" }
    }
}
