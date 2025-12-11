@inline(__always)
func logTrace(_ message: @autoclosure () -> String) {
    #if TraceLogs
    print(message())
    #endif
}

func logError(_ message: String) {
    print("ELEMENTARY ERROR: \(message)")
}

func logWarning(_ message: String) {
    print("ELEMENTARY WARNING: \(message)")
}
