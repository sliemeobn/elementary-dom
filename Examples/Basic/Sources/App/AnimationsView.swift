import ElementaryDOM
import _ElementaryMath

@View
struct AnimationsView {
    @State var angle: Double = 0
    @State var isBallFading: Bool = false
    @State var isOffset: Bool = false
    @State var isRotated: Bool = false

    var content: some View {

        div {
            AnimatedView(angle: angle, isBallFading: isBallFading)
            div(.style(["display": "flex", "flex-direction": "row", "gap": "10px"])) {
                button { "Animate" }
                    .onClick { _ in
                        withAnimation(.linear(duration: 3)) {
                            angle += 1
                            isBallFading.toggle()
                        }
                    }
                Square(color: "blue")
                    //.rotationEffect(.degrees(0))
                    .rotationEffect(.radians(angle), anchor: .topTrailing)
                Square(color: "red")
                    .rotationEffect(.degrees(isRotated ? 360 : 0))
                    .offset(x: isOffset ? 100 : 0)
                    .onClick { _ in
                        withAnimation(.easeInOut(duration: 5)) {
                            isOffset.toggle()
                        }
                        withAnimation(.bouncy(duration: 3).delay(isRotated ? 0 : 2)) {
                            isRotated.toggle()
                        }
                    }
            }
        }
    }
}

@View
struct AnimatedView {
    var angle: Double
    var isBallFading: Bool

    let size = 100.0
    var x: Double { size * (1 - cos(angle)) }
    var y: Double { size * (1 - sin(angle)) }

    var content: some View {
        p { "Angle: \(angle) x: \(x) y: \(y)" }
        div {
            Ball()
                .attributes(
                    .style([
                        "transform": "translate(\(x)px, \(y)px)",
                        "position": "relative",
                    ])
                )
                .opacity(isBallFading ? 0.1 : 1)
        }.attributes(
            .style([
                "height": "\(2 * size + 10)px",
                "width": "\(2 * size + 10)px",
                "position": "relative",
            ])
        )
    }
}

@View
struct Square {
    var color: String

    var content: some View {
        span {}
            .attributes(
                .style([
                    "background": color,
                    "height": "20px",
                    "width": "20px",
                ])
            )
    }
}

extension AnimatedView: Animatable {
    var animatableValue: Double {
        get { angle }
        set { angle = newValue }
    }
}

@View
struct Ball {
    var content: some HTML<HTMLTag.span> & View {
        span {}
            .attributes(
                .style([
                    "background": "red",
                    "height": "10px",
                    "width": "10px",
                    "border-radius": "50%",
                    "display": "block",
                ])
            )
    }
}
