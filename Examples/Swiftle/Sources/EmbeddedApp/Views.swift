import ElementaryDOM

@View
struct GameView {
    @State var game = Game()

    func onKeyPressed(_ key: EnteredKey) {
        game.handleKey(key)
    }

    var content: some View {
        main(.class("flex flex-col gap-5 items-center h-screen bg-black text-white")) {
            div(.class("flex gap-4 items-center pt-5")) {
                SwiftLogo()
                h1(.class("text-2xl uppercase tracking-wider font-serif")) { "Swiftle" }
                SwiftLogo()
            }

            div(.class("flex flex-col gap-1 font-mono relative")) {
                for guess in game.guesses {
                    GuessView(guess: guess)
                }
            }

            div(.class("relative")) {
                KeyboardView(keyboard: game.keyboard, onKeyPressed: onKeyPressed)
                GameEndOverlay(game: $game)
            }

            footer {
                p(.class("text-xs text-gray-400 text-center")) {
                    "This is a proof of concept demo of an Embedded Swift Wasm app."
                    br()
                    "Find the source code in the "
                    a(.href("https://github.com/sliemeobn/elementary-dom"),
                      .class("text-orange-600 hover:underline"))
                    {
                        "elementary-dom github repository."
                    }
                }
            }
        }.receive(GlobalDocument.onKeyDown) { event in
            guard let key = EnteredKey(event) else { return }
            onKeyPressed(key)
        }
    }
}

@View
struct SwiftLogo {
    var content: some View {
        img(.src("swift-bird.svg"), .class("h-10"))
    }
}

@View
struct GuessView {
    var guess: Guess

    var content: some View {
        div(.class("flex gap-1")) {
            for letter in guess.letters {
                LetterView(guess: letter)
            }
        }
    }
}

@View
struct LetterView {
    var guess: LetterGuess?

    var content: some View {
        div(.class("flex justify-center items-center w-10 h-10")) {
            p(.class("text-xl font-semibold")) {
                guess?.letter.value ?? ""
            }.attributes(.class("text-gray-200"), when: guess?.status == .unknown)
        }
        .attributes(.class("border-2 border-gray-700"), when: guess == nil)
        .attributes(.class("border-2 border-gray-400"), when: guess?.status == .unknown)
        .attributes(.class("bg-green-600"), when: guess?.status == .correctPosition)
        .attributes(.class("bg-yellow-600"), when: guess?.status == .inWord)
        .attributes(.class("bg-gray-600"), when: guess?.status == .notInWord)
    }
}

@View
struct KeyboardView {
    var keyboard: Keyboard
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        div(.class("flex flex-col items-center gap-1.5")) {
            div(.class("flex gap-1")) {
                for letter in keyboard.topRow {
                    KeyboardLetterView(guess: letter, onKeyPressed: onKeyPressed)
                }
            }
            div(.class("flex gap-1")) {
                for letter in keyboard.middleRow {
                    KeyboardLetterView(guess: letter, onKeyPressed: onKeyPressed)
                }
            }
            div(.class("flex gap-1")) {
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

    var content: some View {
        button(.class("flex justify-center items-center w-7 h-10 rounded-sm")) {
            p(.class("text-lg font-semibold")) {
                guess.letter.value
            }
        }
        .enabledMobileActive()
        .attributes(.class("bg-gray-400 active:bg-gray-300"), when: guess.status == .unknown)
        .attributes(.class("bg-gray-600 active:bg-gray-500"), when: guess.status == .notInWord)
        .attributes(.class("bg-yellow-600 active:bg-yellow-500"), when: guess.status == .inWord)
        .attributes(.class("bg-green-600 active:bg-green-500"), when: guess.status == .correctPosition)
        .onClick { _ in
            onKeyPressed(.letter(guess.letter))
        }
    }
}

@View
struct EnterKeyView {
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        button(.class("flex justify-center items-center w-12 h-10 p-2 rounded-sm")) {
            img(.src("enter.svg"))
        }
        .enabledMobileActive()
        .attributes(.class("bg-gray-400 active:bg-gray-300"))
        .onClick { _ in
            onKeyPressed(.enter)
        }
    }
}

@View
struct BackspaceKeyView {
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        button(.class("flex justify-center items-center w-12 h-10 p-1 rounded-sm")) {
            img(.src("backspace.svg"))
        }
        .enabledMobileActive()
        .attributes(.class("bg-gray-400 active:bg-gray-300"))
        .onClick { _ in
            onKeyPressed(.backspace)
        }
    }
}

@View
struct GameEndOverlay {
    @Binding var game: Game

    var content: some View {
        if game.state != .playing {
            div(.class("absolute inset-0 bg-black bg-opacity-60 flex flex-col items-center")) {
                div(.class("flex flex-col gap-2 items-center pt-2 font-bold")) {
                    h1(.class("text-xl uppercase tracking-wider shadow-lg")) {
                        game.state == .won ? "Nice job!" : "Oh no!"
                    }
                    button(.class("bg-orange-500 py-2 px-6 rounded-md shadow-lg")) {
                        "Restart"
                    }.onClick { _ in
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
