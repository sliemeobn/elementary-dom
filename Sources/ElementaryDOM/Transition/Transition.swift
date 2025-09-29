public protocol Transition {
    associatedtype Body: View
    typealias Content = PlaceholderContentView<Self>

    @HTMLBuilder func body(content: Content, phase: TransitionPhase) -> Body
}

public struct FadeTransition: Transition {
    public func body(content: Content, phase: TransitionPhase) -> some View {
        let _ = logTrace("FadeTransition body \(phase)")
        content.opacity(phase.isIdentity ? 1.0 : 0.0)
    }
}

extension Transition where Self == FadeTransition {
    public static var fade: Self { FadeTransition() }
}

extension View {
    public func transition<T: Transition>(_ transition: T) -> _TransitionView<T, Self> {
        _TransitionView(transition: transition, wrapped: self)
    }
}

public struct _TransitionView<T: Transition, V: View>: View {
    public typealias Content = Never
    var transition: T
    var wrapped: V

    public typealias _MountedNode = _TransitionNode<T, V>

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(transition: view.transition, wrapped: view.wrapped, context: context, reconciler: &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.update(transition: view.transition, wrapped: view.wrapped, context: &reconciler)
    }
}

public struct PlaceholderContentView<Value>: View {
    private var makeNodeFn: (borrowing _ViewContext, inout _RenderContext) -> _PlaceholderNode

    init(makeNodeFn: @escaping (borrowing _ViewContext, inout _RenderContext) -> _PlaceholderNode) {
        self.makeNodeFn = makeNodeFn
    }
}

extension PlaceholderContentView: _Mountable {
    public typealias _MountedNode = _PlaceholderNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        view.makeNodeFn(context, &reconciler)
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}

public enum TransitionPhase: Equatable, Sendable {
    case willAppear
    case identity
    case didDisappear

    public var isIdentity: Bool {
        self == .identity
    }

    public var value: Double {
        switch self {
        case .willAppear: -1.0
        case .identity: 0.0
        case .didDisappear: 1.0
        }
    }
}

public final class _PlaceholderNode: _Reconcilable {
    var node: AnyReconcilable

    init(node: AnyReconcilable) {
        self.node = node
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        node.apply(op, &reconciler)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        node.collectChildren(&ops, &context)
    }

    public func unmount(_ context: inout _CommitContext) {
        node.unmount(&context)
    }
}

public final class _TransitionNode<T: Transition, V: View>: _Reconcilable {
    private var transition: T
    private var wrapped: V
    private var node: T.Body._MountedNode?

    private var placeholder: _PlaceholderNode?
    // a transition can theoretically duplicate the content node, but it will be rare
    private var additionalPlaceholders: [_PlaceholderNode] = []

    init(transition: T, wrapped: V, context: borrowing _ViewContext, reconciler: inout _RenderContext) {
        self.transition = transition
        self.wrapped = wrapped

        let placeholder = PlaceholderContentView<T>(makeNodeFn: self.makePlaceholderNode)

        guard reconciler.transaction?.animation != nil else {
            self.node = T.Body._makeNode(
                transition.body(content: placeholder, phase: .identity),
                context: context,
                reconciler: &reconciler
            )
            return
        }

        let transaction = reconciler.transaction
        reconciler.transaction?.disablesAnimation = true
        self.node = T.Body._makeNode(
            transition.body(content: placeholder, phase: .willAppear),
            context: context,
            reconciler: &reconciler
        )

        reconciler.scheduler.registerAnimation(
            AnyAnimatable { [self] context in
                guard let node = self.node else { return false }
                context.transaction = transaction
                T.Body._patchNode(
                    transition.body(content: placeholder, phase: .identity),
                    node: node,
                    reconciler: &context
                )
                return false
            }
        )
    }

    func update(transition: T, wrapped: V, context: inout _RenderContext) {
        self.transition = transition

        if let placeholder {
            V._patchNode(wrapped, node: placeholder.node.unwrap(), reconciler: &context)
        }

        for placeholder in additionalPlaceholders {
            V._patchNode(wrapped, node: placeholder.node.unwrap(), reconciler: &context)
        }
    }

    private func makePlaceholderNode(context: borrowing _ViewContext, reconciler: inout _RenderContext) -> _PlaceholderNode {
        let node = _PlaceholderNode(node: AnyReconcilable(V._makeNode(wrapped, context: context, reconciler: &reconciler)))
        if placeholder == nil {
            placeholder = node
        } else {
            additionalPlaceholders.append(node)
        }
        return node
    }

    public func apply(_ op: _ReconcileOp, _ reconciler: inout _RenderContext) {
        node?.apply(op, &reconciler)
    }

    public func collectChildren(_ ops: inout ContainerLayoutPass, _ context: inout _CommitContext) {
        node?.collectChildren(&ops, &context)
    }

    public func unmount(_ context: inout _CommitContext) {
        node?.unmount(&context)

        node = nil
        placeholder = nil
        additionalPlaceholders.removeAll()
    }
}
