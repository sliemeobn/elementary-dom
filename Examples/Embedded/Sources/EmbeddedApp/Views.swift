import ElementaryDOM

struct GameView: View {
    var game: Game
    var onKeyPressed: (EnteredKey) -> Void
    var onRestart: () -> Void

    var content: some View {
        main(.class("flex flex-col items-center h-screen bg-black text-white")) {
            div(.class("flex gap-4 items-center pt-5")) {
                SwiftLogo()
                h1(.class("text-2xl uppercase tracking-wider font-serif")) { "Swiftle" }
                SwiftLogo()
            }

            div(.class("flex flex-col gap-1 font-mono py-5 relative")) {
                for guess in game.guesses {
                    GuessView(guess: guess)
                }

                GameEndOverlay(game: game, onRestart: onRestart)
            }

            KeyboardView(keyboard: game.keyboard, onKeyPressed: onKeyPressed)
        }
    }
}

struct SwiftLogo: View {
    var content: some View {
        img(.src("swift-bird.svg"), .class("h-10"))
    }
}

struct GuessView: View {
    var guess: Guess

    var content: some View {
        div(.class("flex gap-1")) {
            for letter in guess.letters {
                LetterView(guess: letter)
            }
        }
    }
}

struct LetterView: View {
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

struct KeyboardView: View {
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

struct KeyboardLetterView: View {
    var guess: LetterGuess
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        button(.class("flex justify-center items-center w-7 h-10 rounded-sm")) {
            p(.class("text-lg font-semibold")) {
                guess.letter.value
            }
        }
        .attributes(.class("bg-gray-400"), when: guess.status == .unknown)
        .attributes(.class("bg-green-600"), when: guess.status == .correctPosition)
        .attributes(.class("bg-yellow-600"), when: guess.status == .inWord)
        .attributes(.class("bg-gray-600"), when: guess.status == .notInWord)
        .onClick { _ in
            onKeyPressed(.letter(guess.letter))
        }
    }
}

struct EnterKeyView: View {
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        button(.class("flex justify-center items-center w-12 h-10 p-2 rounded-sm")) {
            img(.src("enter.svg"))
        }
        .attributes(.class("bg-gray-400"))
        .onClick { _ in
            onKeyPressed(.enter)
        }
    }
}

struct BackspaceKeyView: View {
    var onKeyPressed: (EnteredKey) -> Void

    var content: some View {
        button(.class("flex justify-center items-center w-12 h-10 p-1 rounded-sm")) {
            img(.src("backspace.svg"))
        }
        .attributes(.class("bg-gray-400"))
        .onClick { _ in
            onKeyPressed(.backspace)
        }
    }
}

struct GameEndOverlay: View {
    var game: Game
    var onRestart: () -> Void

    var content: some View {
        if game.state != .playing {
            div(.class("absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center")) {
                div(.class("bg-gray-600 p-5 rounded-md flex flex-col gap-4 items-center w-full mx-2")) {
                    h1(.class("text-xl uppercase tracking-wider")) {
                        game.state == .won ? "Nice job!" : "Oh no!"
                    }
                    button(.class("bg-orange-500 p-2 rounded-md w-full")) {
                        "Restart"
                    }.onClick { _ in
                        onRestart()
                    }
                }
            }
        }
    }
}
