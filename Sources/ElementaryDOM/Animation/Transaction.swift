// NOTE: don't let this get to big, it is passed around quite a bit
public struct Transaction {
    // TODO: either main actor or thread local for multi-threaded environments
    internal static var _current: Transaction? = nil
    internal static var lastId: UInt32 = 0

    let _id: UInt32
    var _animationTracker: AnimationTracker?

    public var animation: Animation?
    public var disablesAnimation: Bool = false

    public init(animation: Animation? = nil) {
        defer { Transaction.lastId &+= 1 }
        self._id = Transaction.lastId
        self.animation = animation
    }

    public mutating func addAnimationCompletion(
        criteria: AnimationCompletionCriteria = .logicallyComplete,
        _ onComplete: @escaping () -> Void
    ) {
        tracker.addAnimationCompletion(criteria: criteria, onComplete)
    }

    internal mutating func newAnimation(at frameTime: Double) -> AnimationInstance? {
        guard !disablesAnimation, let animation = animation else { return nil }
        let instanceID = tracker.addAnimation()
        return AnimationInstance(
            startTime: frameTime,
            animation: animation,
            trackingReference: .init(instanceID: instanceID, tracker: tracker)
        )
    }

    private var tracker: AnimationTracker {
        mutating get {
            if _animationTracker == nil {
                _animationTracker = AnimationTracker()
            }
            return _animationTracker!
        }
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
    struct InstanceID: Equatable, Hashable {
        let value: Int
    }

    private var _nextInstanceID: Int = 0
    private var openRemovals: Set<InstanceID> = []
    private var openCompletions: Set<InstanceID> = []
    private var completionCallbacks: [() -> Void] = []
    private var removalCallbacks: [() -> Void] = []

    var areAllCallbacksRun: Bool {
        completionCallbacks.isEmpty && removalCallbacks.isEmpty
    }

    func addAnimation() -> InstanceID {
        _nextInstanceID &+= 1
        let instanceID = InstanceID(value: _nextInstanceID)
        openRemovals.insert(instanceID)
        openCompletions.insert(instanceID)
        return instanceID
    }

    func reportLogicallyComplete(_ instanceID: InstanceID) {
        openCompletions.remove(instanceID)
        checkCallbacks()
    }

    func reportRemoved(_ instanceID: InstanceID) {
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
