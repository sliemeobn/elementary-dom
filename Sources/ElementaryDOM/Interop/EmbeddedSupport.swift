#if hasFeature(Embedded)
    import JavaScriptKit

    let consoleLog = JSObject.global.console.log.function!

    func print(_ message: String) {
        _ = consoleLog(message)
    }
#endif

extension String {
    // TODO: there is probably a better way...
    func utf8Equals(_ other: String) -> Bool {
        guard utf8.count == other.utf8.count else { return false }
        return utf8.elementsEqual(other.utf8)
    }
}

extension String? {
    func utf8Equals(_ other: String?) -> Bool {
        switch (self, other) {
        case (.none, .none):
            return true
        case let (.some(lhs), .some(rhs)):
            return lhs.utf8Equals(rhs)
        default:
            return false
        }
    }
}
