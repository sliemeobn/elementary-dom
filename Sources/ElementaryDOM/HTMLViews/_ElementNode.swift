public final class _ElementNode: _Reconcilable {
    var identifier: String = ""
    var child: AnyReconcilable!

    var domNode: ManagedDOMReference?
    var mountedModifieres: [AnyUnmountable]?
    var layoutObservers: [any DOMLayoutObserver]?

    var childrenLayoutStatus: ChildrenLayoutStatus = .init()

    struct ChildrenLayoutStatus {
        var isDirty: Bool = false
        var count: Int = 0
    }

    private(set) var parentNode: _ElementNode?

    init(
        tag: String,
        viewContext: borrowing _ViewContext,
        context: inout _RenderContext,
        makeChild: (borrowing _ViewContext, inout _RenderContext) -> AnyReconcilable
    ) {
        precondition(viewContext.parentElement != nil, "parent element must be set")
        self.parentNode = viewContext.parentElement
        self.identifier = "\(tag):\(ObjectIdentifier(self))"

        logTrace("created element \(identifier) in \(viewContext.parentElement!.identifier)")
        viewContext.parentElement!.reportChangedChildren(.elementAdded, context: &context)

        var viewContext = copy viewContext
        viewContext.parentElement = self
        let modifiers = viewContext.modifiers.take()
        self.layoutObservers = viewContext.layoutObservers.take()

        context.scheduler.addCommitAction(
            CommitAction { [self] context in
                precondition(self.domNode == nil, "element already has a DOM node")
                let ref = context.dom.createElement(tag)
                self.domNode = ManagedDOMReference(reference: ref, status: .added)

                self.mountedModifieres = modifiers.map {
                    $0.mount(ref, &context)
                }
            }
        )

        self.child = makeChild(viewContext, &context)
    }

    init(
        root: DOM.Node,
        viewContext: consuming _ViewContext,
        context: inout _RenderContext,
        makeChild: (borrowing _ViewContext, inout _RenderContext) -> AnyReconcilable
    ) {
        self.domNode = .init(reference: root, status: .unchanged)
        self.identifier = "\("_root_"):\(ObjectIdentifier(self))"

        var viewContext = viewContext
        let layoutObservers = viewContext.layoutObservers.take()
        viewContext.parentElement = self

        if !layoutObservers.isEmpty {
            self.layoutObservers = layoutObservers
        }

        self.child = makeChild(viewContext, &context)
    }

    func updateChild<Node: _Reconcilable>(
        _ context: inout _RenderContext,
        as: Node.Type = Node.self,
        block: (_ node: Node, _ context: inout _RenderContext) -> Void
    ) {
        block(self.child.unwrap(), &context)
    }

    func reportChangedChildren(_ change: ElementNodeChildrenChange, context: inout _RenderContext) {
        // TODO: count needed storage for children

        let wasClean = !childrenLayoutStatus.isDirty
        if wasClean {
            childrenLayoutStatus.isDirty = true
            context.scheduler.addPlacementAction(CommitAction(run: performLayout(_:)))
        }

        if wasClean,
            let ref = domNode?.reference,
            let observers = layoutObservers,
            !observers.isEmpty
        {
            for observer in observers {
                observer.willLayoutChildren(parent: ref, context: &context)
            }
        }
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        assert(domNode != nil, "unitialized element in layout pass")
        self.domNode?.collectLayoutChanges(&ops, type: .element)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        switch op {
        case .startRemoval:
            assert(domNode != nil, "unitialized element in startRemoval")
            domNode?.status = .removed
            parentNode?.reportChangedChildren(.elementRemoved, context: &reconciler)
        case .cancelRemoval:
            domNode?.status = .moved
            parentNode?.reportChangedChildren(.elementAdded, context: &reconciler)
        case .markAsMoved:
            assert(domNode != nil, "unitialized element in markAsMoved")
            domNode?.status = .moved
            parentNode?.reportChangedChildren(.elementChanged, context: &reconciler)
        }
    }

    public func unmount(_ context: inout _CommitContext) {
        let c = self.child.take()!
        c.unmount(&context)

        for modifier in mountedModifieres! {
            modifier.unmount(&context)
        }
        self.mountedModifieres = nil

        if let observers = layoutObservers {
            for observer in observers {
                observer.unmount(&context)
            }
        }
        layoutObservers = nil

        self.domNode = nil
        self.parentNode = nil
    }

    func performLayout(_ context: inout _CommitContext) {
        guard let ref = domNode?.reference else {
            preconditionFailure("unitialized element in commitChanges - maybe this can be fine?")
        }

        guard childrenLayoutStatus.isDirty else {
            assertionFailure("layout triggered on non-dirty node")
            return
        }
        childrenLayoutStatus.isDirty = false

        // 1. Collect current children
        var ops = ContainerLayoutPass()  // TODO: initialize with count, could be allocationlessly somehow
        child!.collectChildren(&ops, &context)

        // 2. Apply DOM changes
        if ops.canBatchReplace {
            if ops.isAllRemovals {
                context.dom.replaceChildren([], in: ref)
            } else if ops.isAllAdditions {
                context.dom.replaceChildren(ops.entries.map { $0.reference }, in: ref)
            } else {
                fatalError("cannot batch replace children of \(ref) because it is not all removals or all additions")
            }
        } else {
            var sibling: DOM.Node?

            for entry in ops.entries.reversed() {
                switch entry.kind {
                case .added, .moved:
                    context.dom.insertChild(entry.reference, before: sibling, in: ref)
                    sibling = entry.reference
                case .removed:
                    context.dom.removeChild(entry.reference, from: ref)
                case .leaving:
                    sibling = entry.reference
                    break
                case .unchanged:
                    sibling = entry.reference
                    break
                }
            }
        }

        if let observers = layoutObservers, !observers.isEmpty {
            for observer in observers {
                observer.didLayoutChildren(parent: ref, entries: ops.entries, context: &context)
            }
        }
    }
}

enum ElementNodeChildrenChange {
    case elementAdded
    case elementChanged
    // TODO: leaving?
    case elementRemoved
}

struct ManagedDOMReference: ~Copyable {
    let reference: DOM.Node
    var status: ContainerLayoutPass.Entry.Status
}

extension ManagedDOMReference {
    mutating func collectLayoutChanges(_ ops: inout ContainerLayoutPass, type: ContainerLayoutPass.Entry.NodeType) {
        ops.append(.init(kind: status, reference: reference, type: type))
        self.status = .unchanged
    }
}
