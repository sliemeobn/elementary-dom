import Synchronization

enum _ThreadLocal {
    // TODO: make this actually a thread local
    nonisolated(unsafe) static var value: UnsafeMutableRawPointer?
}

// TODO: Mutex causes swift compiler crash on github CI - figure out why
#if hasFeature(Embedded) || os(Linux)
// TODO: figure this out
final class MutexBox<State>: @unchecked Sendable {
    private var state: State

    init(_ state: sending State) {
        self.state = state
    }

    func withLock<Result>(_ body: (inout sending State) -> sending Result) -> sending Result {
        return body(&state)
    }

    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
#else
final class MutexBox<State: ~Copyable>: Sendable {
    private let state: Mutex<State>

    init(_ state: consuming sending State) {
        self.state = Mutex(state)
    }

    func withLock<Result>(_ body: sending (inout sending State) -> sending Result) -> sending Result {
        return state.withLock(body)
    }

    var id: ObjectIdentifier { ObjectIdentifier(self) }
}
#endif
