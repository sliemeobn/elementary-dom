struct AnyParentElememnt {
    enum Change {
        case added
        case moved
        case removed
    }

    let identifier: String  // TODO: make this an object identifier
    let reportChangedChildren: (Change, inout _ReconcilerBatch) -> Void
}

struct AnyFunctionNode {
    let identifier: ObjectIdentifier
    let depthInTree: Int
    let runUpdate: (inout _ReconcilerBatch) -> Void
}

struct CommitAction {
    let run: (inout any DOM.Interactor) -> Void
}

public struct _ReconcilerBatch: ~Copyable {
    let scheduler: Scheduler

    private(set) var pendingFunctions: PendingFunctionQueue
    private(set) var parentElement: AnyParentElememnt?
    var commitPlan = CommitPlan()

    var depth: Int  //use with style?

    init(
        scheduler: Scheduler,
        pendingFunctions: consuming PendingFunctionQueue = .init()
    ) {
        self.pendingFunctions = pendingFunctions
        self.scheduler = scheduler

        depth = 0
    }

    mutating func addFunction(_ function: AnyFunctionNode) {
        pendingFunctions.registerFunctionForUpdate(function)
    }

    mutating func withCurrentLayoutContainer(_ container: AnyParentElememnt, block: (inout Self) -> Void) {
        let previous = parentElement
        parentElement = container
        block(&self)
        parentElement = previous
    }

    consuming func drain() -> CommitPlan {
        while let next = pendingFunctions.next() {
            next.runUpdate(&self)
        }

        return commitPlan
    }

    // TODO: init with assert, but would need to make commitplan optional
}

struct PendingFunctionQueue: ~Copyable {
    private var functionsToRun: [AnyFunctionNode] = []

    var isEmpty: Bool { functionsToRun.isEmpty }

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

struct CommitPlan: ~Copyable {
    private var nodes: [CommitAction] = []
    private var placements: [CommitAction] = []

    var isEmpty: Bool { nodes.isEmpty && placements.isEmpty }

    mutating func addNodeAction(_ action: CommitAction) {
        nodes.append(action)
    }

    mutating func addPlacementAction(_ action: CommitAction) {
        placements.append(action)
    }

    consuming func flush(dom: inout any DOM.Interactor) {
        for node in nodes {
            node.run(&dom)
        }
        nodes.removeAll()

        for placement in placements.reversed() {
            placement.run(&dom)
        }
        placements.removeAll()
    }

    deinit {
        assert(isEmpty, "dirty DOM element dropped without being committed")
    }
}

// TODO: move to a better place, maybe use a span with lifecycle stuff
public struct ContainerLayoutPass: ~Copyable {
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

struct RemovalPass: ~Copyable {
    fileprivate final class Liftime {
        let callback: () -> Void

        init(callback: @escaping () -> Void) {
            self.callback = callback
        }

        deinit {
            callback()
        }
    }

    private let lifetime: Liftime

    init(_ callback: @escaping () -> Void) {
        // NOTE: maybe defer allocation somehow
        lifetime = Liftime(callback: callback)
    }

    struct Deferral: ~Copyable {
        fileprivate let lifetime: Liftime
        consuming func release() {}
    }

    func deferRemoval() -> Deferral {
        Deferral(lifetime: lifetime)
    }
}

struct ManagedDOMReference: ~Copyable {
    let reference: DOM.Node
    var status: ContainerLayoutPass.Entry.Status
}
