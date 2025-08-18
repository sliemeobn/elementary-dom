public final class TextNode: MountedNode {
    var value: String
    var domNode: ManagedDOMReference

    init(_ newValue: String, context: inout _ReconcilerBatch) {
        self.value = newValue
        self.domNode = .init(reference: context.dom.createText(newValue), status: .added)

        context.parentElement.registerNewChild(&context)
    }

    func patch(_ newValue: String, context: inout _ReconcilerBatch) {
        logTrace("patching text \(value) with \(newValue)")
        guard !value.utf8Equals(newValue) else { return }
        context.dom.patchText(domNode.reference, with: newValue, replacing: value)
        self.value = newValue
    }

    public func runLayoutPass(_ ops: inout LayoutPass) {
        domNode.collectLayoutChanges(&ops)
    }
    public func startRemoval(reconciler: inout _ReconcilerBatch) {
        reconciler.parentElement.registerRemovedChild(reconciler: &reconciler)
    }
}
