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

        // deduplicate
        for node in run.nodesWithChangedChildren {
            guard let reference = node.domReference else { fatalError("DOM Children update requested for a non-dom node") }
            dom.replaceChildren(node.getChildReferenceList(), in: reference)
        }
    }

    func runUpdatedFunctionNode(_ node: Node, context: inout UpdateRun) {
        guard case let .function(function, state) = node.value else {
            fatalError("Expected function")
        }

        let value = withObservationTracking {
            function.getContent(state)
        } onChange: { [self] in
            print("change triggered")
            self.reportObservedChange(in: node)
        }

        reconcile(parent: node, withContent: value, context: &context)
    }

    func reconcile(parent: Node, withContent renderedElement: _RenderedView, context: inout UpdateRun) {
        guard !parent.children.isEmpty else {
            parent.replaceChildren(mount(renderedElement, context: &context))
            if !parent.children.isEmpty {
                context.registerNodeForChildrenUpdate(parent)
            }
            return
        }

        // handle lists special
        if case let .list(elements) = renderedElement.value {
            var newList = [Node]() // TODO: avoidable allocation
            let renderedViews = elements.flattened()

            // things definitely have changed if the number of children is different
            // otherwise, the loop will detect if nothing changed
            var hasChanged = parent.children.count != renderedViews.count

            for (index, newValue) in renderedViews.enumerated() {
                // TODO: use identitiy and do proper collection diffing
                if parent.children.count > index {
                    let existingNode = parent.children[index]
                    if !tryPatchSingleNode(existingNode, newValue, context: &context) {
                        hasChanged = true
                        newList.append(contentsOf: mount(newValue, context: &context))
                    } else {
                        newList.append(existingNode)
                    }
                } else {
                    hasChanged = true
                    newList.append(contentsOf: mount(newValue, context: &context))
                }
            }

            if hasChanged {
                parent.replaceChildren(newList)
                context.registerNodeForChildrenUpdate(parent)
            }
        } else {
            var hasPatched = false
            if parent.children.count == 1 {
                let child = parent.children[0]
                if tryPatchSingleNode(child, renderedElement, context: &context) {
                    hasPatched = true
                }
            }

            if !hasPatched {
                parent.replaceChildren(mount(renderedElement, context: &context))
                context.registerNodeForChildrenUpdate(parent)
            }
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
            // TODO: check of identity
            _ = function
            node.updateValue(.function(newFunction, state))
            context.registerFunctionForUpdate(node)
        case (_, .list(_)):
            preconditionFailure("List must be flattened before reconciling")
        default:
            // print("could not patch \(node.value) with \(element.value)")
            return false
        }
        return true
    }

    func mount(_ renderedElement: _RenderedView, context: inout UpdateRun) -> [Node] {
        var nodes: [Node] = [] // TODO: avoidable allocation

        switch renderedElement.value {
        case let .text(text):
            nodes.append(Node(value: .text(text), domReference: dom.createText(text)))
        case let .element(element, content):
            let domNode = dom.createElement(element.tagName)
            let node = Node(value: .element(element), domReference: domNode)
            dom.patchElementAttributes(domNode, with: element.attributes, replacing: .none)
            dom.patchEventListeners(domNode, with: element.listerners, replacing: .none, sink: node.getOrMakeEventSync(dom))

            node.replaceChildren(mount(content, context: &context))
            nodes.append(node)
        case let .list(elements):
            for element in elements {
                nodes.append(contentsOf: mount(element, context: &context))
            }
        case let .function(function):
            let state = function.createInitialState?()
            let node = Node(value: .function(function, state))
            nodes.append(node)
            context.registerFunctionForUpdate(node)
        case .nothing:
            ()
        }

        for node in nodes {
            guard let reference = node.domReference else { continue }
            let childRefs = node.getChildReferenceList()
            if !childRefs.isEmpty {
                dom.replaceChildren(childRefs, in: reference)
            }
        }

        return nodes
    }
}

extension Reconciler {
    final class Node {
        enum Value {
            case root
            case text(String)
            case element(DomElement)
            case function(RenderFunction, ManagedState?)
        }

        private(set) var value: Value
        private(set) var domReference: DOMReference?
        private(set) var children: [Node] // TODO: avoidable allocation, think about using sibling pattern
        private(set) var depthInTree: Int = 0
        private(set) var eventSink: DOMInteractor.EventSink?

        // TODO: no weak in embedded, figure out retain cycles
        private(set) var parent: Node?

        init(value: Value, domReference: DOMReference? = nil) {
            self.value = value
            self.domReference = domReference
            children = []
        }

        static func root(domNode: DOMReference) -> Node {
            Node(value: .root, domReference: domNode)
        }

        func replaceChildren(_ newValue: [Node]) {
            // TODO: unmounting, checks

            children = newValue
            for child in children {
                child.parent = self
                child.depthInTree = depthInTree + 1
            }
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
    }
}

private extension [_RenderedView] {
    // TODO: ideally we could avoid all the list allocations, if views would more directly "append" their stuff into a reconciler
    consuming func flattened() -> [_RenderedView] {
        flatMap { element in
            switch element.value {
            case let .list(children):
                return children.flattened()
            case .nothing:
                return []
            default:
                return [element]
            }
        }
    }
}
