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

// TODO: find a better name for this
struct AnyFunctionNode {
    let identifier: ObjectIdentifier
    let depthInTree: Int
    let runUpdate: (inout _RenderContext) -> Void
}

struct AnyAnimatable {
    let progressAnimation: (inout _RenderContext) -> Bool
}

struct CommitAction {
    // TODO: is there a way to make this allocation-free?
    let run: (inout _CommitContext) -> Void
}

public struct _RenderContext: ~Copyable {
    let scheduler: Scheduler
    var currentFrameTime: Double
    var transaction: Transaction?

    private(set) var pendingFunctions: PendingFunctionQueue
    private(set) var parentElement: AnyParentElememnt?
    var depth: Int = 0

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

    consuming func drain() {
        while let next = pendingFunctions.next() {
            next.runUpdate(&self)
        }
    }
}

public struct _CommitContext: ~Copyable {
    let dom: any DOM.Interactor
    let currentFrameTime: Double

    private var prePaintActions: [() -> Void] = []
    private var postPaintActions: [() -> Void] = []

    init(dom: any DOM.Interactor, currentFrameTime: Double) {
        self.dom = dom
        self.currentFrameTime = currentFrameTime
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

struct AnyNode {
    private var ref: AnyObject

    @inline(__always)
    init(_ node: some _Reconcilable) {
        self.ref = node
    }

    @inline(__always)
    func unwrap<Node: _Reconcilable>(as: Node.Type = Node.self) -> Node {
        unsafeDowncast(ref, to: Node.self)
    }
}
