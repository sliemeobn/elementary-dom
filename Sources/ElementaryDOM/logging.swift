@inline(__always)
func logTrace(_ message: @autoclosure () -> String) {
    #if DEBUG  // TODO: make this conditional somehow
    if true {
        print(message())
    }
    #endif
}

func logError(_ message: String) {
    print("ELEMENTARY ERROR: \(message)")
}

func logWarning(_ message: String) {
    print("ELEMENTARY WARNING: \(message)")
}
