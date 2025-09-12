struct AnyParentElememnt {
    enum Change {
        case elementAdded
        case elementChanged
        // TODO: leaving?
        case elementRemoved
    }

    let identifier: String  // TODO: make this an object identifier
    let reportChangedChildren: (Change, inout _RenderContext) -> Void
}

struct AnyFunctionNode {
    let identifier: ObjectIdentifier
    let depthInTree: Int
    let runUpdate: (inout _RenderContext) -> Void
}

struct CommitAction {
    // TODO: is there a way to make this allocation-free?
    let run: (inout _CommitContext) -> Void
}

public struct _RenderContext: ~Copyable {
    let scheduler: Scheduler
    var commitPlan: CommitPlan

    private(set) var pendingFunctions: PendingFunctionQueue
    private(set) var parentElement: AnyParentElememnt?
    var depth: Int = 0

    init(
        scheduler: Scheduler,
        commitPlan: consuming CommitPlan,
        pendingFunctions: consuming PendingFunctionQueue = .init()
    ) {
        self.pendingFunctions = pendingFunctions
        self.scheduler = scheduler
        self.commitPlan = commitPlan

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
}

public struct _CommitContext: ~Copyable {
    let dom: any DOM.Interactor

    private var prePaintActions: [() -> Void] = []
    private var postPaintActions: [() -> Void] = []

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    mutating func addPrePaintAction(_ action: @escaping () -> Void) {
        prePaintActions.append(action)
    }

    mutating func addPostPaintAction(_ action: @escaping () -> Void) {
        postPaintActions.append(action)
    }

    consuming func drain() {
        for action in prePaintActions {
            action()
        }
        prePaintActions.removeAll()

        // TODO: make this better, clearer scheduling
        dom.runNext { [postPaintActions] in
            for action in consume postPaintActions {
                action()
            }
        }
    }
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
        var context = _CommitContext(dom: dom)
        for node in nodes {
            node.run(&context)
        }
        nodes.removeAll()

        for placement in placements.reversed() {
            placement.run(&context)
        }
        placements.removeAll()

        context.drain()
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
            case leaving  // TODO: something can be leaving and moved....
            case removed
            case moved
        }

        let kind: Status
        let reference: DOM.Node
    }
}

struct ManagedDOMReference: ~Copyable {
    let reference: DOM.Node
    var status: ContainerLayoutPass.Entry.Status
}
