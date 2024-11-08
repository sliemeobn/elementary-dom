import Synchronization
#if canImport(Foundation)
import Foundation
#endif

// TODO: figure this out
enum _ThreadLocal {
    #if !canImport(Foundation) || os(WASI)
    nonisolated(unsafe) static var value: UnsafeMutableRawPointer?
    #else
    private struct Key: Hashable {}

    static var value: UnsafeMutableRawPointer? {
        get { Thread.current.threadDictionary[Key()] as! UnsafeMutableRawPointer? }
        set { Thread.current.threadDictionary[Key()] = newValue }
    }
    #endif
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
