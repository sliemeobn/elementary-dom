// NOTE: don't let this get to big, it is passed around quite a bit
public struct Transaction {
    // TODO: either main actor or thread local for multi-threaded environments
    internal static var _current: Transaction? = nil
    internal static var lastId: UInt32 = 0

    let _id: UInt32
    let _animationTracker: AnimationTracker = .init()

    public var animation: Animation?
    public var disablesAnimation: Bool = false

    public init(animation: Animation? = nil) {
        defer { Transaction.lastId &+= 1 }
        self._id = Transaction.lastId
        self.animation = animation
    }

    public func addAnimationCompletion(
        criteria: AnimationCompletionCriteria = .logicallyComplete,
        _ onComplete: @escaping () -> Void
    ) {
        _animationTracker.addAnimationCompletion(criteria: criteria, onComplete)
    }

    // TODO: extendable storage via typed keys
}

public func withTransaction<Result, Failure>(
    _ transaction: Transaction,
    _ body: () throws(Failure) -> Result
) throws(Failure) -> Result {
    let previous = Transaction._current
    Transaction._current = transaction
    defer {
        Transaction._current = previous
    }
    return try body()
}

public func withAnimation<Result, Failure>(
    _ animation: Animation? = .default,
    _ body: () throws(Failure) -> Result
) throws(Failure) -> Result {
    try withTransaction(.init(animation: animation), body)
}

public func withAnimation<Result, Failure>(
    _ animation: Animation? = .default,
    completionCriteria: AnimationCompletionCriteria = .logicallyComplete,
    _ body: () throws(Failure) -> Result,    
    completion: @escaping () -> Void
) throws(Failure) -> Result {
    let transaction = Transaction(animation: animation)
    transaction.addAnimationCompletion(criteria: completionCriteria, completion)
    return try withTransaction(transaction, body)
}

public struct AnimationCompletionCriteria: Hashable {
    internal enum Value {
        case logicallyComplete
        case removed
    }

    internal var value: Value

    public static var logicallyComplete: Self {
        .init(value: .logicallyComplete)
    }

    public static var removed: Self {
        .init(value: .removed)
    }
}

final class AnimationTracker {
    struct Instance {
        private let instanceID: Int
        private let tracker: AnimationTracker

        init(instanceID: Int, tracker: AnimationTracker) {
            self.instanceID = instanceID
            self.tracker = tracker
        }

        func reportLogicallyComplete() {
            tracker.reportLogicallyComplete(instanceID)
        }

        func reportRemoved() {
            tracker.reportRemoved(instanceID)
        }
    }

    private var _nextInstanceID: Int = 0
    private var openRemovals: Set<Int> = []
    private var openCompletions: Set<Int> = []
    private var completionCallbacks: [() -> Void] = []
    private var removalCallbacks: [() -> Void] = []

    var areAllCallbacksRun: Bool {
        completionCallbacks.isEmpty && removalCallbacks.isEmpty
    }

    func addAnimation() -> Instance {
        _nextInstanceID &+= 1
        let instanceID = _nextInstanceID
        openRemovals.insert(instanceID)
        openCompletions.insert(instanceID)

        return Instance(instanceID: _nextInstanceID, tracker: self)
    }

    private func reportLogicallyComplete(_ instanceID: Int) {
        openCompletions.remove(instanceID)
        checkCallbacks()
    }

    private func reportRemoved(_ instanceID: Int) {
        openCompletions.remove(instanceID)
        openRemovals.remove(instanceID)
        checkCallbacks()
    }

    func addAnimationCompletion(criteria: AnimationCompletionCriteria = .logicallyComplete, _ onComplete: @escaping () -> Void) {
        switch criteria.value {
        case .logicallyComplete:
            completionCallbacks.append(onComplete)
        case .removed:
            removalCallbacks.append(onComplete)
        }
    }

    func checkCallbacks() {
        if openCompletions.isEmpty {
            for callback in completionCallbacks {
                callback()
            }
            completionCallbacks.removeAll()
        }

        if openRemovals.isEmpty {
            for callback in removalCallbacks {
                callback()
            }

            removalCallbacks.removeAll()
        }
    }

    deinit {
        for callback in completionCallbacks {
            callback()
        }
        for callback in removalCallbacks {
            callback()
        }
    }
}
