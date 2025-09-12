public protocol __FunctionView: View where _MountedNode == _FunctionNode<Self, Self.Content._MountedNode> {
    associatedtype __ViewState

    static func __initializeState(from view: borrowing Self) -> __ViewState
    static func __restoreState(_ storage: __ViewState, in view: inout Self)

    static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self)

    static func __areEqual(a: borrowing Self, b: borrowing Self) -> Bool
}

public extension __FunctionView {

    static func _makeNode(
        _ view: consuming Self,
        context: consuming _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        .init(
            value: view,
            context: context,
            reconciler: &reconciler
        )
    }

    static func _patchNode(
        _ view: consuming Self,
        node: inout _MountedNode,
        reconciler: inout _RenderContext
    ) {
        node.patch(view, context: &reconciler)
    }
}

public extension __FunctionView where __ViewState == Void {
    static func __initializeState(from view: borrowing Self) {}
    static func __restoreState(_ storage: __ViewState, in view: inout Self) {}
}

public extension __FunctionView {
    static func __areEqual(a: borrowing Self, b: borrowing Self) -> Bool where Self: Equatable {
        a == b
    }

    static func __areEqual(a: borrowing Self, b: Self) -> Bool where Self: __ViewEquatable {
        Self.__arePropertiesEqual(a: a, b: b)
    }

    static func __areEqual(a: borrowing Self, b: borrowing Self) -> Bool where Self: Equatable & __ViewEquatable {
        // that is the question.... but I think if explicit equality is provided, we should use it
        a == b
    }

    static func __areEqual(a: borrowing Self, b: borrowing Self) -> Bool {
        false
    }
}
