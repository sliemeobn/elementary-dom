import ElementaryDOM
import ElementaryMath

@View
struct AnimationsView {
    @State var angle: Double = 0

    var content: some View {

        div {
            AnimatedView(angle: angle)
            button { "Animate" }
                .onClick { _ in
                    withAnimation(.bouncy(duration: 1)) {
                        angle += 1
                    }
                }
        }
    }
}

@View
struct AnimatedView {
    var angle: Double

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
        }.attributes(
            .style([
                "height": "\(2 * size + 10)px",
                "width": "\(2 * size + 10)px",
                "position": "relative",
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
