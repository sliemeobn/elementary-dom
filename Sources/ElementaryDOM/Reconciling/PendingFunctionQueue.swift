struct PendingFunctionQueue: ~Copyable {
    private var functionsToRun: [AnyFunctionNode] = []

    var isEmpty: Bool { functionsToRun.isEmpty }

    // TODO: add transaction here?
    mutating func registerFunctionForUpdate(_ node: AnyFunctionNode) {
        logTrace("registering function run \(node.identifier)")
        // sorted insert by depth in reverse order, avoiding duplicates
        var inserted = false

        for index in functionsToRun.indices {
            let existingNode = functionsToRun[index]
            if existingNode.identifier == node.identifier {
                inserted = true
                break
            }
            if node.depthInTree > existingNode.depthInTree {
                functionsToRun.insert(node, at: index)
                inserted = true
                break
            }
        }
        if !inserted {
            functionsToRun.append(node)
        }
    }

    mutating func next() -> AnyFunctionNode? {
        functionsToRun.popLast()
    }

    deinit {
        assert(functionsToRun.isEmpty, "pending functions dropped without being run")
    }
}
