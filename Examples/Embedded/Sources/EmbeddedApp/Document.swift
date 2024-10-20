import ElementaryDOM
import JavaScriptKit

enum Document {
    static let document = JSObject.global.document

    static func onKeyDown(_ callback: @escaping (KeyboardEvent) -> Void) {
        _ = document.addEventListener("keydown", JSClosure { event in
            callback(KeyboardEvent(event[0].object!)!)
            return .undefined
        })
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
