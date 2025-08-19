// FIXME:NONCOPYABLE make ~Copyable once associatedtype is supported
public final class TextNode: MountedNode {
    var value: String
    var domNode: ManagedDOMReference?

    init(_ newValue: String, context: inout _ReconcilerBatch) {
        self.value = newValue
        self.domNode = nil

        context.commitPlan.addNodeAction(CommitAction(run: createDOMNode(_:)))
        context.parentElement?.reportChangedChildren(.added, &context)
    }

    func patch(_ newValue: String, context: inout _ReconcilerBatch) {
        logTrace("patching text \(value) with \(newValue)")
        guard !value.utf8Equals(newValue) else { return }

        context.commitPlan.addNodeAction(CommitAction(run: updateDOMNode(_:)))
        self.value = newValue
    }

    func createDOMNode(_ dom: inout any DOM.Interactor) {
        self.domNode = ManagedDOMReference(reference: dom.createText(value), status: .added)
    }

    func updateDOMNode(_ dom: inout any DOM.Interactor) {
        guard let ref = domNode?.reference else {
            preconditionFailure("unitialized text node in update - maybe this can be fine?")
        }

        dom.patchText(ref, with: value)
    }

    public func runLayoutPass(_ ops: inout ContainerLayoutPass) {
        assert(domNode != nil, "unitialized text node in layout pass")
        domNode?.collectLayoutChanges(&ops)
    }

    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        domNode?.status = .removed
        reconciler.parentElement?.reportChangedChildren(.removed, &reconciler)
    }
}
