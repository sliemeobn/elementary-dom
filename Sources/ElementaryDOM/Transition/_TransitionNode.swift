public final class _TransitionNode<T: Transition, V: View>: _Reconcilable {
    private var transition: T
    private var wrapped: V
    private var node: T.Body._MountedNode?

    private var placeholderView: PlaceholderContentView<T>?
    private var placeholderNode: _PlaceholderNode?
    // a transition can theoretically duplicate the content node, but it will be rare
    private var additionalPlaceholderNodes: [_PlaceholderNode] = []

    init(transition: T, wrapped: V, context: borrowing _ViewContext, reconciler: inout _RenderContext) {
        self.transition = transition
        self.wrapped = wrapped

        placeholderView = PlaceholderContentView<T>(makeNodeFn: self.makePlaceholderNode)

        guard reconciler.transaction?.animation != nil else {
            self.node = T.Body._makeNode(
                transition.body(content: placeholderView!, phase: .identity),
                context: context,
                reconciler: &reconciler
            )
            return
        }

        let transaction = reconciler.transaction
        reconciler.transaction?.disablesAnimation = true
        self.node = T.Body._makeNode(
            transition.body(content: placeholderView!, phase: .willAppear),
            context: context,
            reconciler: &reconciler
        )

        reconciler.scheduler.registerAnimation(
            AnyAnimatable { [self] context in
                guard let node = self.node, let placeholderView = self.placeholderView else { return .completed }
                context.transaction = transaction
                T.Body._patchNode(
                    transition.body(content: placeholderView, phase: .identity),
                    node: node,
                    reconciler: &context
                )
                return .completed
            }
        )
    }

    func update(transition: T, wrapped: V, context: inout _RenderContext) {
        self.transition = transition

        if let placeholderNode {
            V._patchNode(wrapped, node: placeholderNode.node.unwrap(), reconciler: &context)
        }

        for placeholder in additionalPlaceholderNodes {
            V._patchNode(wrapped, node: placeholder.node.unwrap(), reconciler: &context)
        }
    }

    private func makePlaceholderNode(context: borrowing _ViewContext, reconciler: inout _RenderContext) -> _PlaceholderNode {
        let node = _PlaceholderNode(node: AnyReconcilable(V._makeNode(wrapped, context: context, reconciler: &reconciler)))
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
            guard reconciler.transaction?.isAnimated == true else {
                node?.apply(op, &reconciler)
                return
            }

            reconciler.transaction?.addAnimationCompletion(criteria: .removed) { [scheduler = reconciler.scheduler] in
                scheduler.registerAnimation(
                    AnyAnimatable { [self] context in
                        guard let node = self.node else { return .completed }
                        node.apply(.startRemoval, &context)
                        return .completed
                    }
                )
            }

            T.Body._patchNode(
                transition.body(content: placeholderView, phase: .didDisappear),
                node: node!,
                reconciler: &reconciler
            )
        case .cancelRemoval:
            T.Body._patchNode(
                transition.body(content: placeholderView, phase: .identity),
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
        animation != nil
    }
}
