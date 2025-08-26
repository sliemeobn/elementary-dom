import ElementaryDOM

struct DeinitSnifferView: View {
    static func _makeNode(
        _ view: consuming DeinitSnifferView,
        context: consuming ElementaryDOM._ViewContext,
        reconciler: inout ElementaryDOM._RenderContext
    ) -> _MountedNode {
        _MountedNode(callback: view.callback)
    }

    static func _patchNode(
        _ view: consuming DeinitSnifferView,
        context: consuming ElementaryDOM._ViewContext,
        node: inout _MountedNode,
        reconciler: inout ElementaryDOM._RenderContext
    ) {
        node.callback = view.callback
    }

    class _MountedNode: _Reconcilable {
        func apply(_ op: ElementaryDOM._ReconcileOp, _ reconciler: inout ElementaryDOM._RenderContext) {}

        func collectChildren(_ ops: inout ElementaryDOM.ContainerLayoutPass, _ context: inout ElementaryDOM._CommitContext) {}

        func unmount(_ context: inout ElementaryDOM._CommitContext) {
            print("sniffer unmount")
        }

        var callback: () -> Void

        init(callback: @escaping () -> Void) {
            print("sniffer init")
            self.callback = callback
        }

        deinit {
            print("sniffer deinit")
            callback()
        }
    }

    var callback: () -> Void

    var body: Never {
        fatalError()
    }

}
