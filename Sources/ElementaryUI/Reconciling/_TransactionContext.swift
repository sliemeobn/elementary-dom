public struct _TransactionContext: ~Copyable {
    let scheduler: Scheduler
    let currentFrameTime: Double
    private(set) var transaction: Transaction

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

    mutating func addFunction(_ function: AnyFunctionNode) {
        pendingFunctions.registerFunctionForUpdate(function, transaction: transaction)
    }

    // TODO: review this whole ordeal
    mutating func withModifiedTransaction(modifier: (inout Transaction) -> Void, _ body: (inout _TransactionContext) -> Void) {
        let previous = self.transaction
        modifier(&self.transaction)
        body(&self)
        self.transaction = previous
    }

    consuming func drain() {
        while let (node, transaction) = pendingFunctions.next() {
            self.transaction = transaction ?? .init()
            node.runUpdate(&self)
        }
    }
}
