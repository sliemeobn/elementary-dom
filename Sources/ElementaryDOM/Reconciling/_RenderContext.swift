// TOOD: finally find a good name for this
public struct _RenderContext: ~Copyable {
    let scheduler: Scheduler
    var currentFrameTime: Double
    var transaction: Transaction?

    private(set) var pendingFunctions: PendingFunctionQueue

    init(
        scheduler: Scheduler,
        currentTime: Double,
        transaction: Transaction?,
        pendingFunctions: consuming PendingFunctionQueue = .init()
    ) {
        self.pendingFunctions = pendingFunctions
        self.scheduler = scheduler
        self.currentFrameTime = currentTime
        self.transaction = transaction
    }

    mutating func addFunction(_ function: AnyFunctionNode) {
        pendingFunctions.registerFunctionForUpdate(function)
    }

    consuming func drain() {
        while let next = pendingFunctions.next() {
            next.runUpdate(&self)
        }
    }
}
