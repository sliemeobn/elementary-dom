import Elementary

final class FLIPLayoutObserver: DOMLayoutObserver {
    private var childNodes: [DOM.Node] = []
    private var containerNode: DOM.Node?
    private var animateContainerSize: Bool

    init(animateContainerSize: Bool) {
        self.animateContainerSize = animateContainerSize
    }

    func update(animateContainerSize: Bool) {
        self.animateContainerSize = animateContainerSize
    }

    func willLayoutChildren(parent: DOM.Node, context: inout _RenderContext) {
        context.scheduler.flip.scheduleAnimationOf(childNodes, inParent: parent, context: &context)

        if animateContainerSize {
            context.scheduler.flip.scheduleAnimationOf(parent, context: &context)
        }
    }

    func didLayoutChildren(parent: DOM.Node, entries: [ContainerLayoutPass.Entry], context: inout _CommitContext) {
        childNodes.removeAll(keepingCapacity: true)
        childNodes.reserveCapacity(entries.count)

        for entry in entries where entry.type == .element {
            switch entry.kind {
            case .added, .unchanged, .moved:
                childNodes.append(entry.reference)
            case .leaving:
                childNodes.append(entry.reference)
                context.scheduler.flip.markAsLeaving(entry.reference)
            case .removed:
                context.scheduler.flip.markAsRemoved(entry.reference)
            }
        }
    }

    func unmount(_ context: inout _CommitContext) {
        // TODO: figure this out
    }
}
