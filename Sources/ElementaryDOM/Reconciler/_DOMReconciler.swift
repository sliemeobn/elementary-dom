struct RemovalCoordinator: ~Copyable {

    struct PendingOp: ~Copyable {
        let coordinator: RemovalCoordinator

        consuming func signal() {

        }
    }
}

public struct _ReconcilerBatch: ~Copyable {
    let dom: any DOM.Interactor
    let reportObservedChange: (any FunctionNode) -> Void

    private(set) var nodesWithChangedChildren: [any Layoutable]
    // TODO: make this a "with" function
    var parentElement: any ParentElement
    var pendingFunctions: PendingFunctionQueue
    var depth: Int

    init(
        dom: any DOM.Interactor,
        parentElement: any ParentElement,
        pendingFunctions: consuming PendingFunctionQueue,
        reportObservedChange: @escaping (any FunctionNode) -> Void
    ) {
        self.dom = dom
        self.parentElement = parentElement
        self.pendingFunctions = pendingFunctions
        self.reportObservedChange = reportObservedChange

        nodesWithChangedChildren = []
        depth = 0
    }

    mutating func registerNodeForChildrenUpdate(_ node: any Layoutable) {
        logTrace("registerNodeForChildrenUpdate \(node.identifier)")
        nodesWithChangedChildren.append(node)
    }

    mutating func run() {
        logTrace("performUpdateRun started")

        // re-run functions
        while let next = pendingFunctions.popNextFunctionNode() {
            next.runUpdate(reconciler: &self)
        }

        // TODO: collect this but move it out for extra pass handling
        // perform child-layout passes
        for node in nodesWithChangedChildren.reversed() {
            logTrace("performing children pass for \(node.identifier)")
            node.performChildrenPass(&self)
        }

        logTrace("performUpdateRun finished")
    }

    struct PendingFunctionQueue: ~Copyable {
        private var functionsToRun: [any FunctionNode] = []

        var isEmpty: Bool { functionsToRun.isEmpty }

        mutating func popNextFunctionNode() -> (any FunctionNode)? {
            functionsToRun.popLast()
        }

        mutating func registerFunctionForUpdate(_ node: any FunctionNode) {
            logTrace("registering function run \(node.identifier)")
            // sorted insert by depth in reverse order, avoiding duplicates
            var inserted = false

            for index in functionsToRun.indices {
                let existingNode = functionsToRun[index]
                if existingNode === node {
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
    }
}

// TODO: move to a better place, maybe use a span with lifecycle stuff
public struct LayoutPass {
    var entries: [Entry]
    private(set) var isAllRemovals: Bool = true
    private(set) var isAllAdditions: Bool = true

    var canBatchReplace: Bool {
        (isAllRemovals || isAllAdditions) && entries.count > 1
    }

    init() {
        entries = []
    }

    mutating func append(_ entry: Entry) {
        entries.append(entry)
        isAllAdditions = isAllAdditions && entry.kind == .added
        isAllRemovals = isAllRemovals && entry.kind == .removed
    }

    struct Entry {
        enum Status {
            case unchanged
            case added
            case leaving
            case removed
            case moved
        }

        let kind: Status
        let reference: DOM.Node
    }
}

struct ManagedDOMReference: ~Copyable {
    let reference: DOM.Node
    var status: LayoutPass.Entry.Status
}
