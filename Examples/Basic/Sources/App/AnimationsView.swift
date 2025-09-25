import ElementaryDOM
import _ElementaryMath

@View
struct AnimationsView {
    @State var angle: Double = 0
    @State var isBallFading: Bool = false

    var content: some View {

        div {
            AnimatedView(angle: angle, isBallFading: isBallFading)
            button { "Animate" }
                .onClick { _ in
                    withAnimation(.smooth(duration: 1.2)) {
                        angle += 1
                        isBallFading.toggle()
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
        let _ = print("body with angle: \(angle) and isBallFading: \(isBallFading)")
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
