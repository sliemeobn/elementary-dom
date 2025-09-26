struct ReactivePropertyAccessList: Sendable {
    struct Entry: Sendable {
        var tracker: ReactivityTracker
        var properties: Set<PropertyID> = []

        init(_ tracker: ReactivityTracker) {
            self.tracker = tracker
        }

        consuming func merged(with other: consuming Entry) -> Entry {
            properties.formUnion(other.properties)
            return self
        }
    }

    var entries = [ObjectIdentifier: Entry]()

    mutating func add(_ property: PropertyID, tracker: ReactivityTracker) {
        entries[tracker.id, default: Entry(tracker)].properties.insert(property)
    }

    mutating func add(contensOf other: ReactivePropertyAccessList) {
        for (id, entry) in other.entries {
            entries[id, default: Entry(entry.tracker)].properties.formUnion(entry.properties)
        }
    }
}

struct ReactiveTrackingSession: Sendable {
    private struct State {
        var subscriptions: [ReactivityTracker.SubscriptionToken] = []
        var isCancelled = false
    }

    private let state = MutexBox(State())

    public init() {}

    func add(subscriptions: [ReactivityTracker.SubscriptionToken]) {
        state.withLock {
            guard !$0.isCancelled else { return }
            $0.subscriptions.append(contentsOf: subscriptions)
        }
    }

    public func cancel() {
        let subscriptions = state.withLock {
            let tokens = $0.subscriptions
            $0.subscriptions = []
            return tokens
        }
        for subscription in subscriptions {
            subscription.cancel()
        }
    }
}

private func withAccessTracking<T>(_ block: () -> T) -> (T, ReactivePropertyAccessList?) {
    var accessList: ReactivePropertyAccessList?

    let result = withUnsafeMutablePointer(to: &accessList) { ptr in
        let previous = _ThreadLocal.value
        _ThreadLocal.value = UnsafeMutableRawPointer(ptr)
        defer {
            if let scoped = ptr.pointee, let previous {
                if var prevList = previous.assumingMemoryBound(to: ReactivePropertyAccessList?.self).pointee {
                    prevList.add(contensOf: scoped)
                    previous.assumingMemoryBound(to: ReactivePropertyAccessList?.self).pointee = prevList
                } else {
                    previous.assumingMemoryBound(to: ReactivePropertyAccessList?.self).pointee = scoped
                }
            }
            _ThreadLocal.value = previous
        }
        return block()
    }
    return (result, accessList)
}

extension ReactiveTrackingSession {
    func trackWillSet(for accessList: consuming ReactivePropertyAccessList, _ observer: @Sendable @escaping (PropertyID) -> Void) {
        add(
            subscriptions: accessList.entries.values.map { entry in
                entry.tracker.registerTracking(for: entry.properties, willSet: observer)
            }
        )
    }

    func trackDidSet(for accessList: consuming ReactivePropertyAccessList, _ observer: @Sendable @escaping (PropertyID) -> Void) {
        add(
            subscriptions: accessList.entries.values.map { entry in
                entry.tracker.registerTracking(for: entry.properties, didSet: observer)
            }
        )
    }
}

public func withReactiveTracking<T>(
    _ apply: () -> T,
    onChange: @autoclosure () -> @Sendable () -> Void
) -> T {
    let (result, accessList) = withAccessTracking {
        apply()
    }
    if let accessList = accessList {
        let onChange = onChange()
        let session = ReactiveTrackingSession()
        session.trackWillSet(for: accessList) { _ in
            onChange()
            session.cancel()
        }
    }
    return result
}

package struct TrackingSession {
    var _cancel: (() -> Void)?

    init() {}

    init(_ cancel: @escaping () -> Void) {
        _cancel = cancel
    }

    package consuming func cancel() {
        _cancel?()
    }
}

package func withReactiveTrackingSession<T>(
    _ apply: () -> T,
    onWillSet: @autoclosure () -> @Sendable () -> Void
) -> (T, TrackingSession) {
    let (result, accessList) = withAccessTracking {
        apply()
    }
    if let accessList = accessList {
        let onWillSet = onWillSet()
        let session = ReactiveTrackingSession()
        session.trackWillSet(for: accessList) { [onWillSet] _ in
            onWillSet()
        }
        return (result, TrackingSession(session.cancel))
    }
    return (result, TrackingSession())
}
