public protocol __FunctionView: View where _MountedNode == _FunctionNode<Self, Self.Content._MountedNode> {
    associatedtype __ViewState

    static func __initializeState(from view: borrowing Self) -> __ViewState
    static func __restoreState(_ storage: __ViewState, in view: inout Self)

    static func __applyContext(_ context: borrowing _ViewContext, to view: inout Self)

    static func __areEqual(a: borrowing Self, b: borrowing Self) -> Bool

    static func __getAnimatableData(from view: borrowing Self) -> AnimatableVector
    static func __setAnimatableData(_ data: AnimatableVector, to view: inout Self)
}

public extension __FunctionView {

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
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
        node: _MountedNode,
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
    static func __getAnimatableData(from view: borrowing Self) -> AnimatableVector {
        .d0
    }

    static func __setAnimatableData(_ data: AnimatableVector, to view: inout Self) {
        // do nothing
        assertionFailure("__setAnimatableData called on view that does not support animatable data")
    }
}

public extension __FunctionView where Self: Animatable {
    static func __getAnimatableData(from view: borrowing Self) -> AnimatableVector {
        view.animatableValue.animatableVector
    }

    static func __setAnimatableData(_ data: AnimatableVector, to view: inout Self) {
        view.animatableValue = Value(data)
    }
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
