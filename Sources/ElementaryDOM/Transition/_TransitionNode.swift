public final class _TransitionNode<T: Transition, V: View>: _Reconcilable {
    private var value: _TransitionView<T, V>
    private var node: T.Body._MountedNode?

    private var placeholderView: PlaceholderContentView<T>?
    private var placeholderNode: _PlaceholderNode?
    // a transition can theoretically duplicate the content node, but it will be rare
    private var additionalPlaceholderNodes: [_PlaceholderNode] = []

    init(view: consuming _TransitionView<T, V>, context: borrowing _ViewContext, reconciler: inout _RenderContext) {
        self.value = view
        placeholderView = PlaceholderContentView<T>(makeNodeFn: self.makePlaceholderNode)

        if let animation = value.animation {
            reconciler.transaction.animation = animation
        }

        // the idea is that with disablesAnimation set to true, only the top-level transition will be animated after a mount will be animated
        guard reconciler.transaction.isAnimated == true else {
            self.node = T.Body._makeNode(
                self.value.transition.body(content: placeholderView!, phase: .identity),
                context: context,
                reconciler: &reconciler
            )
            return
        }

        let transaction = reconciler.transaction

        reconciler.transaction.disablesAnimation = true
        self.node = T.Body._makeNode(
            self.value.transition.body(content: placeholderView!, phase: .willAppear),
            context: context,
            reconciler: &reconciler
        )

        // NOTE: ideally we apply the animation before first-paint, but currently we DOM nodes mount their effect during commit
        reconciler.scheduler.registerAnimation(
            AnyAnimatable { [self] context in
                guard let node = self.node, let placeholderView = self.placeholderView else { return .completed }
                context.transaction = transaction
                T.Body._patchNode(
                    self.value.transition.body(content: placeholderView, phase: .identity),
                    node: node,
                    reconciler: &context
                )
                return .completed
            }
        )
    }

    func update(view: consuming _TransitionView<T, V>, context: inout _RenderContext) {
        self.value = view

        if let placeholderNode {
            V._patchNode(self.value.wrapped, node: placeholderNode.node.unwrap(), reconciler: &context)
        }

        for placeholder in additionalPlaceholderNodes {
            V._patchNode(self.value.wrapped, node: placeholder.node.unwrap(), reconciler: &context)
        }
    }

    private func makePlaceholderNode(context: borrowing _ViewContext, reconciler: inout _RenderContext) -> _PlaceholderNode {
        let node = _PlaceholderNode(node: AnyReconcilable(V._makeNode(value.wrapped, context: context, reconciler: &reconciler)))
        if placeholderNode == nil {
            placeholderNode = node
        } else {
            additionalPlaceholderNodes.append(node)
        }
        return node
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        guard let placeholderView = placeholderView else { return }
        switch op {
        case .startRemoval:
            if let animation = value.animation {
                reconciler.transaction.animation = animation
            }

            guard reconciler.transaction.isAnimated == true else {
                node?.apply(op, &reconciler)
                return
            }

            // the patch does not go past the placeholder, so this only animates the transition
            T.Body._patchNode(
                value.transition.body(content: placeholderView, phase: .didDisappear),
                node: node!,
                reconciler: &reconciler
            )

            reconciler.transaction.addAnimationCompletion(criteria: .removed) { [scheduler = reconciler.scheduler] in
                // TODO: think if this is the right scheduling, we remove the node in the frame after we flush the final values
                // probably correct, actually...
                scheduler.registerAnimation(
                    AnyAnimatable { [self] context in
                        guard let node = self.node else { return .completed }
                        node.apply(.startRemoval, &context)
                        return .completed
                    }
                )
            }
        case .cancelRemoval:
            // TODO: check this, stuff is for sure missing for reversible transitions
            T.Body._patchNode(
                value.transition.body(content: placeholderView, phase: .identity),
                node: node!,
                reconciler: &reconciler
            )
        case .markAsMoved:
            node?.apply(op, &reconciler)
        }
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        node?.collectChildren(&ops, &context)
    }

    public func unmount(_ context: inout _CommitContext) {
        node?.unmount(&context)

        node = nil
        placeholderNode = nil
        additionalPlaceholderNodes.removeAll()
    }
}

private extension Transaction {
    var isAnimated: Bool {
        animation != nil && !disablesAnimation
    }
}
