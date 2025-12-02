// TOOD: finally find a good name for this
public struct _RenderContext: ~Copyable {
    let scheduler: Scheduler
    var currentFrameTime: Double
    var transaction: Transaction

    /// Accessor to scheduler's FLIPManager
    var flip: FLIPScheduler {
        scheduler.flip
    }

    private(set) var pendingFunctions: PendingFunctionQueue

    init(
        scheduler: Scheduler,
        currentTime: Double,
        transaction: Transaction? = nil,
        pendingFunctions: consuming PendingFunctionQueue = .init()
    ) {
        self.pendingFunctions = pendingFunctions
        self.scheduler = scheduler
        self.currentFrameTime = currentTime
        self.transaction = transaction ?? .init()
    }

    mutating func addFunction(_ function: AnyFunctionNode, transaction: Transaction) {
        pendingFunctions.registerFunctionForUpdate(function, transaction: transaction)
    }

    consuming func drain() {
        while let (node, transaction) = pendingFunctions.next() {
            self.transaction = transaction ?? .init()
            node.runUpdate(&self)
        }
    }
}
