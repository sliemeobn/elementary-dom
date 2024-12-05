// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class Reconciler<DOMInteractor: DOMInteracting> {
    typealias DOMReference = DOMInteractor.Node

    var dom: DOMInteractor
    let root: Node

    private var nextUpdateRun: UpdateRun = .init()

    init(dom: DOMInteractor, root renderedRootView: _RenderedView) {
        self.dom = dom
        root = Node.root(domNode: dom.root)

        var context = UpdateRun()
        reconcile(parent: root, withContent: renderedRootView, context: &context)
        performUpdateRun(context)
    }

    func reportObservedChange(in node: Node) {
        if nextUpdateRun.isEmpty {
            dom.requestAnimationFrame { [self] _ in
                var run = UpdateRun()
                swap(&run, &nextUpdateRun)
                performUpdateRun(run)
            }
        }

        nextUpdateRun.registerFunctionForUpdate(node)
    }

    struct UpdateRun {
        private var functionsToRun: [Node]
        private(set) var nodesWithChangedChildren: [Node]

        init() {
            functionsToRun = []
            nodesWithChangedChildren = []
        }

        var isEmpty: Bool { functionsToRun.isEmpty }

        mutating func registerNodeForChildrenUpdate(_ node: Node) {
            let domOwner = node.owningDOMReferenceNode()
            if !nodesWithChangedChildren.contains(where: { $0 === node }) {
                nodesWithChangedChildren.append(domOwner)
            }
        }

        mutating func popNextFunctionNode() -> Node? {
            functionsToRun.popLast()
        }

        mutating func registerFunctionForUpdate(_ node: Node) {
            // sorted insert by depth in reverse order, avoiding duplicates
            var inserted = false

            for index in functionsToRun.indices {
                let existingNode = functionsToRun[index]
                if existingNode === node {
                    inserted = true
                    break
                }
                if node.depthInTree > existingNode.depthInTree {
                    functionsToRun.insert(node, at: index)
                    inserted = true
                    break
                }
            }
            if !inserted {
                functionsToRun.append(node)
            }
        }
    }

    func performUpdateRun(_ run: consuming UpdateRun) {
        while let next = run.popNextFunctionNode() {
            print("running node on depth \(next.depthInTree)")
            runUpdatedFunctionNode(next, context: &run)
        }

        for node in run.nodesWithChangedChildren {
            guard let reference = node.domReference else { fatalError("DOM Children update requested for a non-dom node") }
            dom.replaceChildren(node.getChildReferenceList(), in: reference)
        }
    }

    func runUpdatedFunctionNode(_ node: Node, context: inout UpdateRun) {
        guard case let .function(function, state) = node.value else {
            fatalError("Expected function")
        }

        // TODO: expose cancellation mechanism and keep track of it
        let value = withReactiveTracking {
            function.getContent(state)
        } onChange: { [self] in
            print("change triggered")
            self.reportObservedChange(in: node)
        }

        reconcile(parent: node, withContent: value, context: &context)
    }

    func reconcile(parent: Node, withContent renderedElement: _RenderedView, context: inout UpdateRun) {
        var hasPatched = false

        if parent.children.isEmpty {
            // this is is expected on first time function runs or the root node
        } else if parent.children.count == 1 {
            hasPatched = tryPatchSingleNode(parent.children[0], renderedElement, context: &context)
        } else {
            fatalError("Unexpected case: Node with multiple children in reconciliation, should only be allowed for list nodes")
        }

        if !hasPatched {
            parent.replaceChild(mount(renderedElement, context: &context))
            context.registerNodeForChildrenUpdate(parent)
        }
    }

    func tryPatchSingleNode(_ node: Node, _ element: _RenderedView, context: inout UpdateRun) -> Bool {
        switch (node.value, element.value) {
        case let (.text(text), .text(newText)):
            if !text.utf8Equals(newText) {
                node.updateValue(.text(newText))
                dom.patchText(node.domReference!, with: newText, replacing: text)
            }
        case let (.element(element), .element(newElement, content)) where element.tagName.utf8Equals(newElement.tagName):
            node.updateValue(.element(newElement))
            dom.patchElementAttributes(node.domReference!, with: newElement.attributes, replacing: element.attributes)
            dom.patchEventListeners(node.domReference!, with: newElement.listerners, replacing: element.listerners, sink: node.getOrMakeEventSync(dom))

            reconcile(parent: node, withContent: content, context: &context)
        case let (.function(function, state), .function(newFunction)):
            // TODO: check of function type? should not be possible to change
            _ = function
            node.updateValue(.function(newFunction, state))
            context.registerFunctionForUpdate(node)
        case let (.lifecycle, .lifecycle(_, content)):
            reconcile(parent: node, withContent: content, context: &context)
        case let (.keyed(key), .keyed(newKey, newContent)):
            if key != newKey {
                // this is the only "expected" case outisde of lists where things need to be replaced
                return false
            }
            reconcile(parent: node, withContent: newContent, context: &context)
        case let (.staticList, .staticList(elements)):
            // this is a bit scary, but static lists can neither change their count not their types
            // so a skipped empty view on mount will stay an empty view, so the indexes will line up again
            var index = 0
            for element in elements where !element.isEmpty {
                guard tryPatchSingleNode(node.children[index], element, context: &context) else {
                    fatalError("Invalid type change detected in static list")
                }
                index += 1
            }
        case let (.dynamicList(keys), .dynamicList(elements)):
            let (newKeys, elements) = elements.extractKeyList()

            if keys == newKeys {
                // fast-pass no change, just patch each child
                for index in node.children.indices {
                    guard tryPatchSingleNode(node.children[index], elements[index], context: &context) else {
                        print("ERROR: Invalid type change detected in dynamic list")
                        fatalError("Invalid type change detected in dynamic list")
                    }
                }
            } else {
                var newChildren = [Node]()
                newChildren.reserveCapacity(newKeys.count)

                for (index, key) in newKeys.enumerated() {
                    // TODO: use collection diffing and infer moves for this
                    if let oldIndex = keys.firstIndex(of: key) {
                        let existingNode = node.children[oldIndex]
                        newChildren.append(existingNode)
                        guard tryPatchSingleNode(existingNode, elements[index], context: &context) else {
                            print("ERROR: Invalid type change detected in dynamic list")
                            fatalError("Invalid type change detected in dynamic list")
                        }
                    } else {
                        if let node = mount(elements[index], context: &context) {
                            newChildren.append(node)
                        }
                    }
                }

                node.updateValue(.dynamicList(newKeys))
                node.replaceChildren(newChildren)
                context.registerNodeForChildrenUpdate(node)
            }
        default:
            print("ERROR: Unexpected change in view structure. \(node.depthInTree) \(element)")
            // TODO: this is a bit harsh, but we should be able to recover from this and just return false?
            fatalError("Unexpected change in view structure")
        }
        return true
    }

    func mount(_ renderedElement: _RenderedView, context: inout UpdateRun) -> Node? {
        switch renderedElement.value {
        case .nothing:
            return nil
        case let .text(text):
            return Node(value: .text(text), domReference: dom.createText(text))
        case let .element(element, content):
            let domNode = dom.createElement(element.tagName)
            let node = Node(value: .element(element), domReference: domNode)
            dom.patchElementAttributes(domNode, with: element.attributes, replacing: .none)
            dom.patchEventListeners(domNode, with: element.listerners, replacing: .none, sink: node.getOrMakeEventSync(dom))

            node.replaceChild(mount(content, context: &context))
            let childRefs = node.getChildReferenceList()
            if !childRefs.isEmpty {
                dom.replaceChildren(childRefs, in: domNode)
            }

            return node
        case let .function(function):
            let state = function.initializeState?()
            let node = Node(value: .function(function, state))
            context.registerFunctionForUpdate(node)
            return node
        case let .lifecycle(hook, content):
            let node = Node(value: .lifecycle(hook), child: mount(content, context: &context))
            return node
        case let .staticList(elements):
            let node = Node(value: .staticList)
            node.replaceChildren(elements.compactMap { mount($0, context: &context) })
            return node
        case let .dynamicList(elements):
            let (keys, elements) = elements.extractKeyList()
            let node = Node(value: .dynamicList(keys))
            node.replaceChildren(elements.compactMap { mount($0, context: &context) })
            return node
        case let .keyed(key, element):
            return Node(value: .keyed(key), child: mount(element, context: &context))
        }
    }
}

extension Reconciler {
    final class Node {
        enum Value {
            case root
            case text(String)
            case element(_DomElement)
            case function(_RenderFunction, _ManagedState?)
            case lifecycle(_LifecycleHook)
            case staticList
            case dynamicList([_RenderedView.Key])
            case keyed(_RenderedView.Key)
            case __unmounted
        }

        private(set) var value: Value
        private(set) var domReference: DOMReference?
        private(set) var children: [Node] // TODO: avoidable allocation, think about using sibling pattern
        private(set) var depthInTree: Int = 0
        private(set) var eventSink: DOMInteractor.EventSink?
        private(set) var parent: Node?

        private var unmountAction: (() -> Void)?

        init(value: Value, domReference: DOMReference? = nil) {
            self.value = value
            self.domReference = domReference
            children = []
        }

        init(value: Value, child: Node?) {
            self.value = value
            domReference = nil
            children = child.map { [$0] } ?? []
        }

        static func root(domNode: DOMReference) -> Node {
            Node(value: .root, domReference: domNode)
        }

        func replaceChild(_ newValue: Node?) {
            // TODO: optimize for single child case
            if let newValue = newValue {
                replaceChildren([newValue])
            } else {
                replaceChildren([])
            }
        }

        func replaceChildren(_ newValue: [Node]) {
            let diff = newValue.difference(from: children, by: ===)

            for change in diff {
                switch change {
                case let .remove(offset, _, _):
                    children[offset].unmount()
                case let .insert(_, element, _):
                    element.mount(in: self)
                }
            }

            children = newValue
        }

        func updateValue(_ value: Value) {
            self.value = value
        }

        func getOrMakeEventSync(_ dom: DOMInteractor) -> DOMInteractor.EventSink {
            if let sink = eventSink {
                return sink
            } else {
                print("creating new event sink for \(value)")
                let sink = dom.makeEventSink { [self] type, event in
                    self.handleEvent(type, event: event)
                }
                eventSink = sink
                return sink
            }
        }

        func handleEvent(_ name: String, event: DOMInteractor.Event) {
            switch value {
            case let .element(element):
                // TODO: how the hell do we type this?
                element.listerners.handleEvent(name, event as AnyObject)
            default:
                print("ERROR: Event handling not supported for \(value)")
            }
        }

        func representingDOMReferences() -> [DOMReference] {
            // TODO: this is not ideal...
            if let reference = domReference {
                return [reference]
            } else {
                return getChildReferenceList()
            }
        }

        func getChildReferenceList() -> [DOMReference] {
            children.flatMap { $0.representingDOMReferences() }
        }

        func owningDOMReferenceNode() -> Node {
            if domReference != nil {
                return self
            } else {
                precondition(parent != nil, "Not allowed on node without parent")
                return parent!.owningDOMReferenceNode()
            }
        }

        private func mount(in parent: Node) {
            precondition(self.parent == nil, "Mounting node that is already mounted")
            self.parent = parent
            depthInTree = parent.depthInTree + 1

            guard case let .lifecycle(hook) = value else { return }
            switch hook {
            case let .onMount(onMount):
                onMount()
            case let .onUnmount(onUnmount):
                unmountAction = onUnmount
            case let .task(task):
                // #if canImport(_Concurrency)
                #if !hasFeature(Embedded)
                // TODO: figure out if Task will ever be available in embedded for wasm
                let task = Task { await task() }
                unmountAction = task.cancel
                #else
                fatalError("Task lifecycle hook not supported without _Concurrency")
                #endif
            case let .onMountReturningCancelFunction(function):
                unmountAction = function()
            case .__none:
                preconditionFailure("__none lifecycle hook on mount")
            }

            value = .lifecycle(.__none)
        }

        private func unmount() {
            print("unmounting node")
            for child in children {
                child.unmount()
            }

            // careful here, retain cycles galore
            parent = nil
            domReference = nil
            eventSink = nil
            value = .__unmounted

            if let action = unmountAction {
                action()
                unmountAction = nil
            }
        }
    }
}

private extension _RenderedView {
    var isEmpty: Bool {
        switch value {
        case .nothing:
            return true
        default:
            return false
        }
    }
}

private extension [_RenderedView] {
    consuming func extractKeyList() -> ([_RenderedView.Key], [_RenderedView]) {
        var keys = [_RenderedView.Key]()
        var elements = [_RenderedView]()

        for (index, element) in enumerated() {
            switch element.value {
            case let .keyed(.explicit(key), content):
                keys.append(.explicit(key))
                elements.append(content)
            default:
                keys.append(.structure(index))
                elements.append(element)
            }
        }

        return (keys, elements)
    }
}
