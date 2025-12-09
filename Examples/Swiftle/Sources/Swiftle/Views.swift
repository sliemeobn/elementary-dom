import ElementaryCSS
import ElementaryUI

@View
struct GameView {
    @State var game = Game()

    func onKeyPressed(_ key: EnteredKey) {
        game.handleKey(key)
    }

    var body: some View {
        FlexColumn(align: .center, gap: 5) {

            FlexRow(align: .center, gap: 4) {
                SwiftLogo()
                Text("SWIFTLE")
                    .style(
                        .fontSize(.xxl),
                        .fontFamily(.serif),
                        .letterSpacing(.em(0.1))
                    )
                SwiftLogo()
            }

            FlexColumn(gap: 1) {
                for guess in game.guesses {
                    GuessView(guess: guess)
                }
            }.style(.fontWeight(.semiBold), .fontSize(.lg), .fontFamily(.monospace))

            Block(.position(.relative)) {
                KeyboardView(keyboard: game.keyboard, onKeyPressed: onKeyPressed)
                GameEndOverlay(game: $game)
            }

            Paragraph(
                .color(.gray400),
                .fontFamily(.sansSerif),
                .textAlign(.center),
                .fontSize(.xs)
            ) {
                "This is a proof of concept demo of an Embedded Swift Wasm app."
                br()
                "Find the source code in the "
                a(.href("https://github.com/elementary-swift/elementary-ui")) {
                    "elementary-ui github repository."
                }
                .style(.color(.orange600))
                .style(when: .hover, .textDecoration("underline"))
            }
        }
        .style(.color(.white), .padding(t: 5), .fontFamily(.sansSerif))
        .receive(GlobalDocument.onKeyDown) { event in
            guard let key = EnteredKey(event) else { return }
            onKeyPressed(key)
        }
    }
}

@View
struct SwiftLogo {
    var body: some View {
        img(.src("swift-bird.svg"))
            .style(.height(10))
    }
}

@View
struct GuessView {
    var guess: Guess

    var body: some View {
        FlexRow(gap: 1) {
            for letter in guess.letters {
                LetterView(guess: letter)
            }
        }
    }
}

@View
struct LetterView {
    var guess: LetterGuess?

    var body: some View {
        Block(.width(10), .height(10), .display(.flex)) {
            Paragraph(.margin(.auto)) {
                guess?.letter.value ?? ""
            }
        }
        .style(
            .color(guess?.status == .unknown ? .gray200 : .white),
            .borderColor(guess == nil ? .gray700 : .gray400),
            .borderWidth(guess == nil || guess?.status == .unknown ? .px(2) : 0),
            .background(guess?.status.backgroundColor ?? .transparent)
        )
    }
}

@View
struct KeyboardView {
    var keyboard: Keyboard
    var onKeyPressed: (EnteredKey) -> Void

    var body: some View {
        FlexColumn(align: .center, gap: 1.5) {
            FlexRow(gap: 1) {
                for letter in keyboard.topRow {
                    KeyboardLetterView(guess: letter, onKeyPressed: onKeyPressed)
                }
            }
            FlexRow(gap: 1) {
                for letter in keyboard.middleRow {
                    KeyboardLetterView(guess: letter, onKeyPressed: onKeyPressed)
                }
            }
            FlexRow(gap: 1) {
                BackspaceKeyView(onKeyPressed: onKeyPressed)
                for letter in keyboard.bottomRow {
                    KeyboardLetterView(guess: letter, onKeyPressed: onKeyPressed)
                }
                EnterKeyView(onKeyPressed: onKeyPressed)
            }
        }
    }
}

@View
struct KeyboardLetterView {
    var guess: LetterGuess
    var onKeyPressed: (EnteredKey) -> Void

    var body: some View {
        button {
            Text(guess.letter.value)
                .style(.margin(.auto), .fontSize(.lg), .fontWeight(.semiBold))
        }
        .style(.width(7), .height(10), .display(.flex), .borderRadius(0.5))
        .enabledMobileActive()
        .style(.background(guess.status.backgroundColor ?? .gray400))
        .style(when: .active, .background(guess.status.activeBackgroundColor))
        .onClick { _ in
            onKeyPressed(.letter(guess.letter))
        }
    }
}

@View
struct EnterKeyView {
    var onKeyPressed: (EnteredKey) -> Void

    var body: some View {
        button {
            img(.src("enter.svg")).style(
                .maxWidth("100%")
            )
        }
        .style(
            .width(12),
            .height(10),
            .padding(2),
            .borderRadius(0.5),
            .display(.flex),
            .alignItems(.center),
            .background(.gray400)
        )
        .style(when: .active, .background(.gray300))
        .enabledMobileActive()
        .onClick { _ in
            onKeyPressed(.enter)
        }
    }
}

@View
struct BackspaceKeyView {
    var onKeyPressed: (EnteredKey) -> Void

    var body: some View {
        button {
            img(.src("backspace.svg")).style(
                .maxWidth("100%")
            )
        }
        .style(
            .width(12),
            .height(10),
            .padding(1),
            .borderRadius(0.5),
            .display(.flex),
            .alignItems(.center),
            .background(.gray400)
        )
        .style(when: .active, .background(.gray300))
        .enabledMobileActive()
        .onClick { _ in
            onKeyPressed(.backspace)
        }
    }
}

@View
struct GameEndOverlay {
    @Binding var game: Game

    var body: some View {
        if game.state != .playing {
            Block(
                .position(.absolute),
                .inset(0),
                .background(.black60a),
                .padding(t: 4),
                .fontWeight(.semiBold)
            ) {
                FlexColumn(align: .center, gap: 2) {
                    Paragraph(.fontSize(.xl), .letterSpacing(.em(0.1)), .textTransform("uppercase")) {
                        game.state == .won ? "Nice job!" : "Oh no!"
                    }
                    button {
                        "Restart"
                    }
                    .style(.background(.orange500), .padding(y: 2, x: 6), .borderRadius(1))
                    .onClick { _ in
                        game = Game()
                    }
                }
            }
        }
    }
}

extension View where Tag == HTMLTag.button {
    func enabledMobileActive() -> _AttributedElement<Self> {
        attributes(.custom(name: "ontouchstart", value: ""))
    }
}

extension EnteredKey {
    init?(_ event: KeyboardEvent) {
        let key = event.key
        if let validLetter = ValidLetter(key) {
            self = .letter(validLetter)
        } else if key.utf8Equals("Backspace") {
            self = .backspace
        } else if key.utf8Equals("Enter") {
            self = .enter
        } else {
            return nil
        }
    }
}

extension LetterGuess.LetterStatus {
    var backgroundColor: CSSColor? {
        switch self {
        case .unknown:
            nil
        case .notInWord:
            .gray600
        case .inWord:
            .yellow600
        case .correctPosition:
            .green600
        }
    }

    var activeBackgroundColor: CSSColor {
        switch self {
        case .unknown:
            .gray300
        case .notInWord:
            .gray500
        case .inWord:
            .yellow500
        case .correctPosition:
            .green500
        }
    }
}
