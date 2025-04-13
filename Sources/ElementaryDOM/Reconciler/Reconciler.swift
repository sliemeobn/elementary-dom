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
            var popped = functionsToRun.popLast()
            while let next = popped {
                switch next.value {
                case .function:
                    return next
                case .__unmounted:
                    // NOTE: this depends on proper "cancellation" of observation/reactivity, not sure if this is 100% preventable
                    // TODO: figure out if this is actually ok and remove the warning
                    printWarning(
                        "Skipping unmounted node in update run: \(next.depthInTree). Not sure yet it this can be prevented 100%"
                    )
                    popped = functionsToRun.popLast()
                default:
                    fatalError("Unexpected node value in update run: \(next.value)")
                }
            }
            return nil
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
            runUpdatedFunctionNode(next, context: &run)
        }

        for node in run.nodesWithChangedChildren {
            guard let reference = node.domReference else {
                fatalError("DOM Children update requested for a non-dom node")
            }
            dom.replaceChildren(node.getChildReferenceList(), in: reference)
        }
    }

    func runUpdatedFunctionNode(_ node: Node, context: inout UpdateRun) {
        guard case .function(let function, let state) = node.value else {
            printError("Expected function node, got \(node.value)")
            fatalError("Expected function node")
        }

        // TODO: expose cancellation mechanism and keep track of it
        let value = withReactiveTracking {
            function.getContent(state)
        } onChange: { [self] in
            self.reportObservedChange(in: node)
        }

        reconcile(parent: node, withContent: value, context: &context)
    }

    func reconcile(
        parent: Node,
        withContent renderedElement: _RenderedView,
        context: inout UpdateRun
    ) {
        var hasPatched = false

        if parent.children.isEmpty {
            // this is is expected on first time function runs or the root node
        } else if parent.children.count == 1 {
            hasPatched = tryPatchSingleNode(parent.children[0], renderedElement, context: &context)
        } else {
            fatalError(
                "Unexpected case: Node with multiple children in reconciliation, should only be allowed for list nodes"
            )
        }

        if !hasPatched {
            parent.replaceChild(makeNode(renderedElement, context: &context))
            context.registerNodeForChildrenUpdate(parent)
        }
    }

    func tryPatchSingleNode(
        _ node: Node,
        _ element: _RenderedView,
        context: inout UpdateRun
    )
        -> Bool
    {
        switch (node.value, element.value) {
        case (.text(let text), .text(let newText)):
            if !text.utf8Equals(newText) {
                node.updateValue(.text(newText))
                dom.patchText(node.domReference!, with: newText, replacing: text)
            }
        case (.element(let element), .element(let newElement, let content))
        where element.tagName.utf8Equals(newElement.tagName):
            node.updateValue(.element(newElement))
            dom.patchElementAttributes(
                node.domReference!,
                with: newElement.attributes,
                replacing: element.attributes
            )
            dom.patchEventListeners(
                node.domReference!,
                with: newElement.listerners,
                replacing: element.listerners,
                sink: node.getOrMakeEventSync(dom)
            )

            reconcile(parent: node, withContent: content, context: &context)
        case (.function(let function, let state), .function(let newFunction)):
            // TODO: check of function type? should not be possible to change
            _ = function
            node.updateValue(.function(newFunction, state))
            context.registerFunctionForUpdate(node)
        case (.lifecycle, .lifecycle(_, let content)):
            reconcile(parent: node, withContent: content, context: &context)
        case (.keyed(let key), .keyed(let newKey, let newContent)):
            if key != newKey {
                // this is the only "expected" case outisde of lists where things need to be replaced
                return false
            }
            reconcile(parent: node, withContent: newContent, context: &context)
        case (.staticList, .staticList(let elements)):
            // this is a bit scary, but static lists can neither change their count not their types
            // so a skipped empty view on mount will stay an empty view, so the indexes will line up again
            var index = 0
            var hasChanged = false
            for element in elements where !element.isEmpty {
                if !tryPatchSingleNode(node.children[index], element, context: &context) {
                    guard let newNode = makeNode(element, context: &context) else {
                        printError("Failed to create new node for static list for index \(index), element: \(element)")
                        fatalError("Failed to create new node for static list")
                    }
                    node.replaceChild(at: index, with: newNode)
                    hasChanged = true
                }

                index += 1
            }

            if hasChanged {
                context.registerNodeForChildrenUpdate(node)
            }
        case (.dynamicList(let keys), .dynamicList(let elements)):
            let (newKeys, elements) = elements.extractKeyList()

            if keys == newKeys {
                // fast-pass no change, just patch each child
                for index in node.children.indices {
                    guard
                        tryPatchSingleNode(node.children[index], elements[index], context: &context)
                    else {
                        printError("Invalid type change detected in dynamic list")
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
                        guard tryPatchSingleNode(existingNode, elements[index], context: &context)
                        else {
                            printError("Invalid type change detected in dynamic list")
                            fatalError("Invalid type change detected in dynamic list")
                        }
                    } else {
                        if let node = makeNode(elements[index], context: &context) {
                            newChildren.append(node)
                        }
                    }
                }

                node.updateValue(.dynamicList(newKeys))
                node.replaceChildren(newChildren)
                context.registerNodeForChildrenUpdate(node)
            }
        default:
            printError("Unexpected change in view structure. \(node.depthInTree) \(element)")
            // TODO: this is a bit harsh, but we should be able to recover from this and just return false?
            fatalError("Unexpected change in view structure")
        }
        return true
    }

    func makeNode(_ renderedElement: _RenderedView, context: inout UpdateRun) -> Node? {
        switch renderedElement.value {
        case .nothing:
            return nil
        case .text(let text):
            return Node(value: .text(text), domReference: dom.createText(text))
        case .element(let element, let content):
            let domNode = dom.createElement(element.tagName)
            let node = Node(
                value: .element(element),
                domReference: domNode,
                child: makeNode(content, context: &context)
            )

            dom.patchElementAttributes(domNode, with: element.attributes, replacing: .none)
            dom.patchEventListeners(
                domNode,
                with: element.listerners,
                replacing: .none,
                sink: node.getOrMakeEventSync(dom)
            )

            let childRefs = node.getChildReferenceList()
            if !childRefs.isEmpty {
                dom.replaceChildren(childRefs, in: domNode)
            }

            return node
        case .function(let function):
            let state = function.initializeState?()
            let node = Node(value: .function(function, state))
            context.registerFunctionForUpdate(node)
            return node
        case .lifecycle(let hook, let content):
            return Node(value: .lifecycle(hook), child: makeNode(content, context: &context))
        case .staticList(let elements):
            return Node(
                value: .staticList,
                children: elements.compactMap { makeNode($0, context: &context) }
            )
        case .dynamicList(let elements):
            let (keys, elements) = elements.extractKeyList()
            let node = Node(
                value: .dynamicList(keys),
                children: elements.compactMap { makeNode($0, context: &context) }
            )
            return node
        case .keyed(let key, let element):
            return Node(value: .keyed(key), child: makeNode(element, context: &context))
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
        private(set) var children: [Node]  // TODO: avoidable allocation, think about using sibling pattern
        private(set) var depthInTree: Int = 0
        private(set) var eventSink: DOMInteractor.EventSink?
        private(set) var parent: Node?

        private var unmountAction: (() -> Void)?

        init(value: Value, domReference: DOMReference? = nil, children: [Node] = []) {
            self.value = value
            self.domReference = domReference
            self.children = children
        }

        convenience init(value: Value, domReference: DOMReference? = nil, child: Node?) {
            self.init(value: value, domReference: domReference, children: child.map { [$0] } ?? [])
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
                case .remove(let offset, _, _):
                    children[offset].unmount()
                case .insert(_, let element, _):
                    element.mount(in: self)
                }
            }

            children = newValue
        }

        func replaceChild(at index: Int, with newValue: Node) {
            children[index].unmount()
            children[index] = newValue
            newValue.mount(in: self)
        }

        func updateValue(_ value: Value) {
            self.value = value
        }

        func getOrMakeEventSync(_ dom: DOMInteractor) -> DOMInteractor.EventSink {
            if let sink = eventSink {
                return sink
            } else {
                let sink = dom.makeEventSink { [self] type, event in
                    self.handleEvent(type, event: event)
                }
                eventSink = sink
                return sink
            }
        }

        func handleEvent(_ name: String, event: DOMInteractor.Event) {
            switch value {
            case .element(let element):
                // TODO: how the hell do we type this?
                element.listerners.handleEvent(name, event as AnyObject)
            default:
                printError("Event handling not supported for \(value)")
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

            // execute lifecycle action on self
            if case .lifecycle(let hook) = value {
                switch hook {
                case .onMount(let onMount):
                    onMount()
                case .onUnmount(let onUnmount):
                    unmountAction = onUnmount
                case .task(let task):
                    // #if canImport(_Concurrency)
                    #if !hasFeature(Embedded)
                    // TODO: figure out if Task will ever be available in embedded for wasm
                    let task = Task { await task() }
                    unmountAction = task.cancel
                    #else
                    fatalError("Task lifecycle hook not supported without _Concurrency")
                    #endif
                case .onMountReturningCancelFunction(let function):
                    unmountAction = function()
                case .__none:
                    preconditionFailure("__none lifecycle hook on mount")
                }

                value = .lifecycle(.__none)
            }

            // mount child nodes that were already added
            for child in children {
                child.mount(in: self)
            }
        }

        private func unmount() {
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

extension _RenderedView {
    fileprivate var isEmpty: Bool {
        switch value {
        case .nothing:
            return true
        default:
            return false
        }
    }
}

extension [_RenderedView] {
    fileprivate consuming func extractKeyList() -> ([_RenderedView.Key], [_RenderedView]) {
        var keys = [_RenderedView.Key]()
        var elements = [_RenderedView]()

        for (index, element) in enumerated() {
            switch element.value {
            case .keyed(.explicit(let key), let content):
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

func printError(_ message: String) {
    print("ELEMENTARY ERROR: \(message)")
}

func printWarning(_ message: String) {
    print("ELEMENTARY WARNING: \(message)")
}
