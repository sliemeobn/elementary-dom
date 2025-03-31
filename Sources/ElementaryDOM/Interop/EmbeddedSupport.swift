extension String {
    // TODO: there is probably a better way...
    @inline(__always)
    func utf8Equals(_ other: String) -> Bool {
        utf8.elementsEqual(other.utf8)
    }
}

extension String? {
    func utf8Equals(_ other: String?) -> Bool {
        switch (self, other) {
        case (.none, .none):
            return true
        case (.some(let lhs), .some(let rhs)):
            return lhs.utf8Equals(rhs)
        default:
            return false
        }
    }
}
