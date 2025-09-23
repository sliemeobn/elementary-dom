import ElementaryDOM
import _ElementaryMath

@View
struct AnimationsView {
    @State var angle: Double = 0
    @State var isBallVisible: Bool = true

    var content: some View {

        div {
            AnimatedView(angle: angle, isBallVisible: isBallVisible)
            button { "Animate" }
                .onClick { _ in
                    withAnimation(.bouncy(duration: 1)) {
                        angle += 1
                    }
                }
            button { "Toggle ball" }
                .onClick { _ in
                    isBallVisible.toggle()
                }
        }
    }
}

@View
struct AnimatedView {
    var angle: Double
    var isBallVisible: Bool

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
                .opacity(isBallVisible ? 1 : 0)
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
