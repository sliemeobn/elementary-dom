// TODO: main-actor stuff very unclear at the moment, ideally not needed at all
final class App<DOMInteractor: _DOMInteracting> {
    typealias Reconciler = _ReconcilerBatch<DOMInteractor>

    var dom: DOMInteractor
    let root: Reconciler.Node.Element

    var nextUpdateRun: Reconciler.PendingFunctionQueue = .init()

    func takeNextUpdateRun() -> Reconciler.PendingFunctionQueue {
        var nextUpdateRun = Reconciler.PendingFunctionQueue()
        swap(&nextUpdateRun, &self.nextUpdateRun)
        return nextUpdateRun
    }

    init<RootView: View>(dom: DOMInteractor, root rootView: consuming RootView) {
        self.dom = dom

        self.root = .init(root: dom.root)

        var reconciler = Reconciler(
            dom: dom,
            parentElement: root,
            pendingFunctions: .init(),
            reportObservedChange: self.reportObservedChange
        )

        self.root.setChild(
            RootView._makeNode(
                consume rootView,
                context: _ViewRenderingContext(),
                reconciler: &reconciler
            )
        )

        reconciler.run()
    }

    func reportObservedChange(in node: Reconciler.Node.Function) {
        if nextUpdateRun.isEmpty {
            //TODO: use next microtask instead of requestAnimationFrame
            dom.requestAnimationFrame { [self] _ in
                var updateRun = Reconciler(
                    dom: dom,
                    parentElement: root,
                    pendingFunctions: self.takeNextUpdateRun(),
                    reportObservedChange: reportObservedChange
                )

                updateRun.run()
            }
        }

        nextUpdateRun.registerFunctionForUpdate(node)
    }

    // func patchSingleNode(
    //     _ nodeValue: Node,
    //     _ element: _RenderedView,
    //     context: inout Node.MutationBatch
    // ) {
    //     logTrace("patchSingleNode \(nodeValue) \(element.value)")
    //     switch (nodeValue, element.value) {
    //     case (.text(let node), .text(let newText)):
    //         if !node.value.utf8Equals(newText) {
    //             node.value = newText
    //             dom.patchText(node.domNode.reference, with: newText, replacing: node.value)
    //         }
    //     case (.element(let node), .element(let newElement, let content))
    //     where node.value.tagName.utf8Equals(newElement.tagName):
    //         node.value = newElement
    //         dom.patchElementAttributes(
    //             node.domNode.reference,
    //             with: newElement.attributes,
    //             replacing: node.value.attributes
    //         )
    //         dom.patchEventListeners(
    //             node.domNode.reference,
    //             with: newElement.listerners,
    //             replacing: node.value.listerners,
    //             sink: node.getOrMakeEventSync(dom)
    //         )

    //         patchSingleNode(node.child, content, context: &context)
    //     case (.function(let function, let state), .function(let newFunction)):
    //         // TODO: check of function type? should not be possible to change
    //         _ = function
    //         nodeValue.updateValue(.function(newFunction, state))
    //         context.registerFunctionForUpdate(nodeValue)
    //     case (.lifecycle, .lifecycle(_, let content)):
    //         reconcile(parent: nodeValue, withContent: content, context: &context)
    //     case (.keyed(let key), .keyed(let newKey, let newContent)):
    //         if key == newKey {
    //             reconcile(parent: nodeValue, withContent: newContent, context: &context)
    //         } else {
    //             nodeValue.updateValue(.keyed(newKey))
    //             nodeValue.replaceChild(makeNode(newContent, context: &context))
    //             context.registerNodeForChildrenUpdate(nodeValue)
    //         }
    //     case (.staticList, .staticList(let elements)):
    //         // this is a bit scary, but static lists can neither change their count not their types
    //         // so a skipped empty view on mount will stay an empty view, so the indexes will line up again
    //         var index = 0
    //         for element in elements where !element.isEmpty {
    //             patchSingleNode(node.children[index], element, context: &context)
    //             index += 1
    //         }
    //     case (.dynamicList(let keys), .dynamicList(let elements)):
    //         let (newKeys, elements) = elements.extractKeyList()

    //         if keys == newKeys {
    //             // fast-pass no change, just patch each child
    //             for index in nodeValue.children.indices {
    //                 patchSingleNode(node.children[index], elements[index], context: &context)
    //             }
    //         } else {
    //             var newChildren = [Node]()
    //             newChildren.reserveCapacity(newKeys.count)

    //             for (index, key) in newKeys.enumerated() {
    //                 // TODO: use collection diffing and infer moves for this
    //                 if let oldIndex = keys.firstIndex(of: key) {
    //                     let existingNode = nodeValue.children[oldIndex]
    //                     newChildren.append(existingNode)
    //                     patchSingleNode(existingNode, elements[index], context: &context)
    //                 } else {
    //                     if let node = makeNode(elements[index], context: &context) {
    //                         newChildren.append(node)
    //                     }
    //                 }
    //             }

    //             nodeValue.updateValue(.dynamicList(newKeys))
    //             nodeValue.replaceChildren(newChildren)
    //             context.registerNodeForChildrenUpdate(nodeValue)
    //         }
    //     default:
    //         logError("Unexpected change in view structure. \(nodeValue.depthInTree) patching \(nodeValue.value) with \(element)")
    //         // TODO: this is a bit harsh, but we should be able to recover from this and just return false?
    //         fatalError("Unexpected change in view structure")
    //     }
    // }

    // func makeNode(_ renderedElement: _RenderedView, in parentElement: Node.Element, context: inout Node.MutationBatch) -> Node {
    //     var value: Node

    //     switch renderedElement.value {
    //     case .nothing:
    //         value = .nothing
    //     case .text(let text):
    //         let domReference = dom.createText(text)
    //         value = .text(.init(value: text, domReference: domReference))
    //     case .element(let element, let content):
    //         let node = Node.Element(
    //             value: element,
    //             domReference: domReference,
    //             child: makeNode(content, in: parentElement, context: &context)
    //         )

    //         dom.patchElementAttributes(domReference, with: element.attributes, replacing: .none)
    //         dom.patchEventListeners(
    //             domReference,
    //             with: element.listerners,
    //             replacing: .none,
    //             sink: node.getOrMakeEventSync(dom)
    //         )

    //         value = .element(node)
    //     case .function(let function):
    //         let node = Node.Function(value: function, child: .nothing, parentElement: parentElement, depthInTree: context.depth + 1)
    //         value = .function(node)
    //         context.pendingFunctions.registerFunctionForUpdate(node)
    //     case .lifecycle(let hook, let content):
    //         let node = Node.Lifecycle(value: hook, child: makeNode(content, in: parentElement, context: &context))
    //         value = .lifecycle(node)
    //     case .staticList(let elements):
    //         let children = elements.compactMap { makeNode($0, in: parentElement, context: &context) }
    //         value = .fragment(children)
    //     case .dynamicList(let elements):
    //         let (keys, elements) = elements.extractKeyList()
    //         let children = elements.compactMap { makeNode($0, in: parentElement, context: &context) }
    //         value = .dynamic(keys, children)
    //     case .keyed(let key, let element):
    //         value = .dynamic([key], [makeNode(element, in: parentElement, context: &context)])
    //     }

    //     return value
    // }
}

// extension ReconcilerNew {
//     final class Node {
//         struct ElementStorage {
//             var domReference: DOMReference
//             var eventSink: DOMInteractor.EventSink?
//             var child: Node?
//         }

//         enum Value {
//             case root
//             case text(String)
//             case element(_DomElement, ElementStorage)
//             case function(_RenderFunction, _ManagedState?)
//             case lifecycle(_LifecycleHook)
//             case staticList
//             case dynamicList([_RenderedView.Key])
//             case keyed(_RenderedView.Key)
//             case __unmounted
//         }

//         private(set) var value: Value
//         private(set) var domReference: DOMReference?

//         private(set) var depthInTree: Int = 0
//         private(set) var eventSink: DOMInteractor.EventSink?
//         private(set) var parent: Node?

//         private var unmountAction: (() -> Void)?

//         init(value: Value, domReference: DOMReference? = nil, children: [Node] = []) {
//             self.value = value
//             self.domReference = domReference
//             self.children = children
//         }

//         convenience init(value: Value, domReference: DOMReference? = nil, child: Node?) {
//             self.init(value: value, domReference: domReference, children: child.map { [$0] } ?? [])
//         }

//         static func root(domNode: DOMReference) -> Node {
//             Node(value: .root, domReference: domNode)
//         }

//         func replaceChild(_ newValue: Node?) {
//             // TODO: optimize for single child case
//             if let newValue = newValue {
//                 replaceChildren([newValue])
//             } else {
//                 replaceChildren([])
//             }
//         }

//         func replaceChildren(_ newValue: [Node]) {
//             #if !hasFeature(Embedded)
//             // NOTE: no diffing available in embedded 6.1 - but it exists on main
//             let diff = newValue.difference(from: children, by: ===)

//             for change in diff {
//                 switch change {
//                 case .remove(let offset, _, _):
//                     children[offset].unmount()
//                 case .insert(_, let element, _):
//                     element.mount(in: self)
//                 }
//             }

//             children = newValue
//             #else
//             // Find nodes to remove
//             for child in children {
//                 if !newValue.contains(where: { $0 === child }) {
//                     child.unmount()
//                 }
//             }

//             // Find nodes to add
//             for newChild in newValue {
//                 if !children.contains(where: { $0 === newChild }) {
//                     newChild.mount(in: self)
//                 }
//             }

//             children = newValue
//             #endif
//         }

//         func replaceChild(at index: Int, with newValue: Node) {
//             children[index].unmount()
//             children[index] = newValue
//             newValue.mount(in: self)
//         }

//         func updateValue(_ value: Value) {
//             self.value = value
//         }

//         func getOrMakeEventSync(_ dom: DOMInteractor) -> DOMInteractor.EventSink {
//             if let sink = eventSink {
//                 return sink
//             } else {
//                 let sink = dom.makeEventSink { [self] type, event in
//                     self.handleEvent(type, event: event)
//                 }
//                 eventSink = sink
//                 return sink
//             }
//         }

//         func handleEvent(_ name: String, event: DOMInteractor.Event) {
//             switch value {
//             case .element(let element):
//                 // TODO: how the hell do we type this?
//                 element.listerners.handleEvent(name, event as AnyObject)
//             default:
//                 logError("Event handling not supported for \(value)")
//             }
//         }

//         func representingDOMReferences() -> [DOMReference] {
//             // TODO: this is not ideal...
//             if let reference = domReference {
//                 return [reference]
//             } else {
//                 return getChildReferenceList()
//             }
//         }

//         func getChildReferenceList() -> [DOMReference] {
//             children.flatMap { $0.representingDOMReferences() }
//         }

//         func owningDOMReferenceNode() -> Node {
//             if domReference != nil {
//                 return self
//             } else {
//                 precondition(parent != nil, "Not allowed on node without parent")
//                 return parent!.owningDOMReferenceNode()
//             }
//         }

//         private func mount(in parent: Node) {
//             precondition(self.parent == nil, "Mounting node that is already mounted")
//             self.parent = parent
//             depthInTree = parent.depthInTree + 1

//             // execute lifecycle action on self
//             if case .lifecycle(let hook) = value {
//                 switch hook {
//                 case .onMount(let onMount):
//                     onMount()
//                 case .onUnmount(let onUnmount):
//                     unmountAction = onUnmount
//                 case .task(let task):
//                     // #if canImport(_Concurrency)
//                     #if !hasFeature(Embedded)
//                     // TODO: figure out if Task will ever be available in embedded for wasm
//                     let task = Task { await task() }
//                     unmountAction = task.cancel
//                     #else
//                     fatalError("Task lifecycle hook not supported without _Concurrency")
//                     #endif
//                 case .onMountReturningCancelFunction(let function):
//                     unmountAction = function()
//                 case .__none:
//                     preconditionFailure("__none lifecycle hook on mount")
//                 }

//                 value = .lifecycle(.__none)
//             }

//             // mount child nodes that were already added
//             for child in children {
//                 child.mount(in: self)
//             }
//         }

//         private func unmount() {
//             for child in children {
//                 child.unmount()
//             }

//             // careful here, retain cycles galore
//             parent = nil
//             domReference = nil
//             eventSink = nil
//             value = .__unmounted

//             if let action = unmountAction {
//                 action()
//                 unmountAction = nil
//             }
//         }
//     }
// }

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

//TODO: make nodes self-initializing, pass context in constructor
