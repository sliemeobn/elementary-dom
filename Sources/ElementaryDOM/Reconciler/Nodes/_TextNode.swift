// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public final class _TextNode: _Reconcilable {
    var value: String
    var domNode: ManagedDOMReference?

    init(_ newValue: String, context: inout _RenderContext) {
        self.value = newValue
        self.domNode = nil

        context.commitPlan.addNodeAction(CommitAction(run: createDOMNode(_:)))
        context.parentElement?.reportChangedChildren(.elementAdded, &context)
    }

    func patch(_ newValue: String, context: inout _RenderContext) {
        logTrace("patching text \(value) with \(newValue)")
        guard !value.utf8Equals(newValue) else { return }

        context.commitPlan.addNodeAction(CommitAction(run: updateDOMNode(_:)))
        self.value = newValue
    }

    func createDOMNode(_ context: inout _CommitContext) {
        self.domNode = ManagedDOMReference(reference: context.dom.createText(value), status: .added)
    }

    func updateDOMNode(_ context: inout _CommitContext) {
        guard let ref = domNode?.reference else {
            preconditionFailure("unitialized text node in update - maybe this can be fine?")
        }

        context.dom.patchText(ref, with: value)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        assert(domNode != nil, "unitialized text node in layout pass")
        domNode?.collectLayoutChanges(&ops)
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        switch op {
        case .startRemoval:
            domNode?.status = .removed
            reconciler.parentElement?.reportChangedChildren(.elementRemoved, &reconciler)
        case .cancelRemoval:
            fatalError("not implemented")
        case .markAsMoved:
            // TODO: checks and handling
            domNode?.status = .moved
            reconciler.parentElement?.reportChangedChildren(.elementChanged, &reconciler)
        }
    }

    public consuming func unmount(_ context: inout _CommitContext) {
        self.domNode = nil
    }
}
