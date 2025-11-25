import Elementary

// TODO: maybe this should not derive from HTML at all, or maybe HTML should already be "View" and _Mountable is an extra requirement for mounting?
// TODO: think about how the square MainActor-isolation with server side usage
public protocol View<Tag>: HTML & _Mountable where Body: HTML & _Mountable {
}

public protocol _Mountable {
    associatedtype _MountedNode: _Reconcilable

    static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode

    static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    )
}

extension Never: _Mountable {
    public typealias _MountedNode = _EmptyNode

    public static func _makeNode(
        _ view: consuming Self,
        context: borrowing _ViewContext,
        reconciler: inout _RenderContext
    ) -> _MountedNode {
        fatalError("This should never be called")
    }

    public static func _patchNode(
        _ view: consuming Self,
        node: _MountedNode,
        reconciler: inout _RenderContext
    ) {}
}
