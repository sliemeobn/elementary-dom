import ElementaryDOM

struct Game {
    enum State {
        case playing
        case won
        case lost
    }

    let solution: String.UTF8View

    private(set) var guesses: [Guess]
    private(set) var keyboard: Keyboard = .init()
    private(set) var state: State = .playing

    init(solution: String = "SWIFT") {
        self.solution = solution.utf8
        guesses = (0 ..< 6).map { _ in Guess() }
    }

    mutating func handleKey(_ key: EnteredKey) {
        guard state == .playing else {
            return
        }

        guard let guessIndex = guesses.firstIndex(where: { $0.status == .notEntered }) else {
            return
        }

        switch key {
        case let .letter(letter):
            guesses[guessIndex].addLetter(letter)
        case .backspace:
            guesses[guessIndex].removeLastLetter()
        case .enter:
            if guesses[guessIndex].areAllLettersEntered {
                guesses[guessIndex].resolve(solution: solution)

                keyboard.applyValidatedGuess(guesses[guessIndex])

                if guesses[guessIndex].areAllLettersCorrect {
                    state = .won
                } else if guessIndex == guesses.endIndex {
                    state = .lost
                }
            }
        }
    }
}

struct Guess {
    enum Status {
        case notEntered
        case entered
    }

    var letters: [LetterGuess?]
    var status: Status = .notEntered

    init(letterCount: Int = 5) {
        letters = (0 ..< letterCount).map { _ in nil }
    }

    var areAllLettersEntered: Bool {
        letters.allSatisfy { $0 != nil }
    }

    var areAllLettersCorrect: Bool {
        letters.allSatisfy { $0?.status == .correctPosition }
    }

    mutating func addLetter(_ letter: ValidLetter) {
        guard let nextIndex = letters.firstIndex(where: { $0 == nil }) else {
            return
        }

        letters[nextIndex] = LetterGuess(letter: letter)
    }

    mutating func removeLastLetter() {
        guard let nextIndex = letters.lastIndex(where: { $0 != nil }) else {
            return
        }

        letters[nextIndex] = nil
    }

    mutating func resolve(solution: String.UTF8View) {
        status = .entered

        var solutionLetters = Array(solution)

        for (index, letter) in letters.enumerated() {
            if letter?.letter.asciiValue == solutionLetters[index] {
                letters[index]!.status = .correctPosition
                solutionLetters[index] = 0
            }
        }

        for (index, letter) in letters.enumerated() where letter?.status == .unknown {
            if let solutionIndex = solutionLetters.firstIndex(of: letter!.letter.asciiValue) {
                letters[index]!.status = .inWord
                solutionLetters[solutionIndex] = 0
            } else {
                letters[index]!.status = .notInWord
            }
        }
    }
}

struct LetterGuess {
    enum LetterStatus: Int {
        case unknown
        case notInWord
        case inWord
        case correctPosition
    }

    var letter: ValidLetter
    var status: LetterStatus = .unknown
}

enum EnteredKey {
    case letter(ValidLetter)
    case backspace
    case enter
}

struct ValidLetter {
    let asciiValue: UInt8

    var value: String {
        String(UnicodeScalar(asciiValue))
    }

    init?(_ value: consuming String) {
        guard value.utf8.count == 1, let asciiValue = value.utf8.first else {
            return nil
        }

        // utf8 uppercase
        if asciiValue >= 97, asciiValue <= 122 {
            self.asciiValue = asciiValue - 32
        } else if asciiValue >= 65, asciiValue <= 90 {
            self.asciiValue = asciiValue
        } else {
            return nil
        }
    }
}

struct Keyboard {
    var letters: [LetterGuess]

    var topRow: ArraySlice<LetterGuess> { letters[0 ..< 10] }
    var middleRow: ArraySlice<LetterGuess> { letters[10 ..< 19] }
    var bottomRow: ArraySlice<LetterGuess> { letters[19 ..< 26] }

    init() {
        // QWERTY layout
        letters = [
            "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
            "A", "S", "D", "F", "G", "H", "J", "K", "L",
            "Z", "X", "C", "V", "B", "N", "M",
        ].map { LetterGuess(letter: ValidLetter($0)!) }
    }

    mutating func applyValidatedGuess(_ guess: Guess) {
        for letter in guess.letters {
            guard let index = letters.firstIndex(where: { $0.letter.asciiValue == letter?.letter.asciiValue }) else {
                preconditionFailure()
            }

            letters[index].applyGuessStatus(letter!.status)
        }
    }
}

extension LetterGuess {
    mutating func applyGuessStatus(_ status: LetterGuess.LetterStatus) {
        guard status != .unknown else { preconditionFailure() }

        if status.rawValue > self.status.rawValue {
            self.status = status
        }
    }
}
