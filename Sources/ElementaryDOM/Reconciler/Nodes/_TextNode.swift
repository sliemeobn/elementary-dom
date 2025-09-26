// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public final class _TextNode: _Reconcilable {
    var value: String
    var domNode: ManagedDOMReference?
    var isDirty: Bool = false
    var parentElement: _ElementNode?

    init(_ newValue: String, viewContext: borrowing _ViewContext, context: inout _RenderContext) {
        self.value = newValue
        self.domNode = nil
        self.parentElement = viewContext.parentElement

        self.parentElement?.reportChangedChildren(.elementAdded, context: &context)

        isDirty = true
        context.scheduler.addNodeAction(
            CommitAction { [self] context in
                self.domNode = ManagedDOMReference(reference: context.dom.createText(newValue), status: .added)
                self.isDirty = false
            }
        )
    }

    func patch(_ newValue: String, context: inout _RenderContext) {
        let needsUpdate = !isDirty && !value.utf8Equals(newValue)
        self.value = newValue

        guard needsUpdate else { return }

        isDirty = true
        context.scheduler.addNodeAction(
            CommitAction { [self] context in
                assert(isDirty, "text node is not dirty")
                assert(domNode != nil, "text node is not mounted")

                (domNode?.reference).map { context.dom.patchText($0, with: value) }
                self.isDirty = false
            }
        )
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        assert(domNode != nil, "unitialized text node in layout pass")
        domNode?.collectLayoutChanges(&ops)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        switch op {
        case .startRemoval:
            domNode?.status = .removed
            self.parentElement?.reportChangedChildren(.elementRemoved, context: &reconciler)
        case .cancelRemoval:
            fatalError("not implemented")
        case .markAsMoved:
            domNode?.status = .moved
            self.parentElement?.reportChangedChildren(.elementChanged, context: &reconciler)
        }
    }

    public func unmount(_ context: inout _CommitContext) {
        self.domNode = nil
        self.parentElement = nil
    }
}
