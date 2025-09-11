import Elementary

public final class _AttributeModifier: DOMElementModifier, Invalidateable {
    typealias Value = _AttributeStorage

    let upstream: _AttributeModifier?
    var tracker: DependencyTracker = .init()

    private var lastValue: Value

    var value: Value {
        var combined = lastValue
        combined.append(upstream?.value ?? .none)
        return combined
    }

    init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
        self.lastValue = value
        self.upstream = upstream[_AttributeModifier.key]
        self.upstream?.tracker.addDependency(self)
        _ = p {}.attributes(.class([""]), .style(["": ""]))
    }

    func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
        if value != lastValue {
            lastValue = value
            tracker.invalidateAll(&context)
        }
    }

    func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
        logTrace("mounting attribute modifier")
        return AnyUnmountable(MountedInstance(node, self, &context))
    }

    func invalidate(_ context: inout _RenderContext) {
        self.tracker.invalidateAll(&context)
    }
}

extension _AttributeModifier {
    final class MountedInstance: Unmountable, Invalidateable {
        let modifier: _AttributeModifier
        let node: DOM.Node

        var isDirty: Bool = false
        var previousValue: _AttributeStorage = .none

        init(_ node: DOM.Node, _ modifier: _AttributeModifier, _ context: inout _CommitContext) {
            self.node = node
            self.modifier = modifier
            self.modifier.tracker.addDependency(self)
            updateDOMNode(&context)
        }

        func invalidate(_ context: inout _RenderContext) {
            guard !isDirty else { return }
            logTrace("invalidating attribute modifier")
            isDirty = true
            context.commitPlan.addNodeAction(CommitAction(run: updateDOMNode(_:)))
        }

        func updateDOMNode(_ context: inout _CommitContext) {
            logTrace("updating attribute modifier")
            let newValue = modifier.value
            context.dom.patchElementAttributes(node, with: newValue, replacing: previousValue)
            isDirty = false
            previousValue = newValue
        }

        func unmount(_ context: inout _CommitContext) {
            logTrace("unmounting attribute modifier")
            self.modifier.tracker.removeDependency(self)
        }
    }
}
