final class FLIPScheduler {
    private var dom: any DOM.Interactor

    // NOTE: extend this to support css properties as well - for now it is always the bounding rect stuff
    private var scheduledAnimations: [DOM.Node: ScheduledNode] = [:]
    private var runningAnimations: [DOM.Node: GeometryAnimation] = [:]

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    func scheduleAnimationOf(_ nodes: [DOM.Node], inParent parentNode: DOM.Node, context: inout _RenderContext) {
        logTrace("scheduling FLIP animations for \(nodes.count) nodes, animation: \(context.transaction.animation != nil)")
        let parentRect = dom.getBoundingClientRect(parentNode)
        for node in nodes {
            guard !scheduledAnimations.keys.contains(node) else {
                logTrace("node \(node) already scheduled for animation")
                continue
            }
            // TODO: we should probably merge stuff or do something better than just ignoring repeated calls
            scheduledAnimations[node] = ScheduledNode(
                transaction: context.transaction,
                geometry: getNodeGeometry(node, scopedTo: parentRect),
                containerNode: parentNode
            )
        }
    }

    func scheduleAnimationOf(_ node: DOM.Node, context: inout _RenderContext) {
        scheduledAnimations[node] = ScheduledNode(
            transaction: context.transaction,
            geometry: getNodeGeometry(node),
            containerNode: nil
        )
    }

    func markAsRemoved(_ node: DOM.Node) {
        scheduledAnimations.removeValue(forKey: node)
        let running = runningAnimations.removeValue(forKey: node)
        running?.cancelAll()
    }

    func markAsLeaving(_ node: DOM.Node, isReentering: Bool = false) {
        assert(scheduledAnimations[node] != nil, "node not scheduled for animation")

        if dom.needsAbsolutePositioning(node) {
            let rect = dom.getAbsolutePositionCoordinates(node)
            scheduledAnimations[node]?.layoutAction = .moveAbsolute(rect: rect)
        }
    }

    func commitScheduledAnimations(context: inout _CommitContext) {

        commitPreMeasurementChanges(context: &context)

        measureLastAndCreateAnimations(context: &context)

        progressAllAnimations(context: &context)
    }

    private func commitPreMeasurementChanges(context: inout _CommitContext) {

        for (node, animation) in scheduledAnimations {
            // TODO: find a good way to preserve velocities of redirected animations
            // TODO: preserve previous position if it was absolute
            // undo all running animations that are effected
            runningAnimations[node]?.cancelAll()

            switch animation.layoutAction {
            case .none:
                continue
            case .moveAbsolute(let rect):
                // Extract current style values before setting new ones
                let stylePosition = context.dom.makeStyleAccessor(node, cssName: "position")
                let styleLeft = context.dom.makeStyleAccessor(node, cssName: "left")
                let styleTop = context.dom.makeStyleAccessor(node, cssName: "top")
                let styleWidth = context.dom.makeStyleAccessor(node, cssName: "width")
                let styleHeight = context.dom.makeStyleAccessor(node, cssName: "height")

                // Extract previous style values for later reversal
                let previousValues = PreviousStyleValues(
                    position: stylePosition.get(),
                    left: styleLeft.get(),
                    top: styleTop.get(),
                    width: styleWidth.get(),
                    height: styleHeight.get()
                )
                // TODO: store previousValues for reversal when animation completes
                _ = previousValues

                logTrace(
                    "setting position of node \(node) to absolute, left: \(rect.x)px, top: \(rect.y)px, width: \(rect.width)px, height: \(rect.height)px"
                )

                stylePosition.set("absolute")
                styleLeft.set("\(rect.x)px")
                styleTop.set("\(rect.y)px")
                styleWidth.set("\(rect.width)px")
                styleHeight.set("\(rect.height)px")
            }
        }
    }

    private func measureLastAndCreateAnimations(context: inout _CommitContext) {
        // measures all last states and calculates all new animations

        // parent rect cache
        let parentRects: [DOM.Node: DOM.Rect] = Dictionary(
            uniqueKeysWithValues: Set(scheduledAnimations.values.compactMap { $0.containerNode })
                .compactMap { node -> (DOM.Node, DOM.Rect)? in
                    (node, dom.getBoundingClientRect(node))
                }
        )

        // measure all LAST states
        for (node, animation) in scheduledAnimations {
            // we keep these for cancelling running animations, but there is nothing new to schedule
            guard animation.transaction.animation != nil else { continue }

            var lastGeometry: NodeGeometry

            if let parent = animation.containerNode, let parentRect = parentRects[parent] {
                lastGeometry = getNodeGeometry(node, scopedTo: parentRect)
            } else {
                lastGeometry = getNodeGeometry(node)
            }

            runningAnimations[node] =
                GeometryAnimation(
                    node: node,
                    first: animation.geometry,
                    last: lastGeometry,
                    transaction: animation.transaction,
                    frameTime: context.currentFrameTime
                )
        }

        scheduledAnimations.removeAll()
    }

    func progressAllAnimations(context: inout _CommitContext) {
        // applies all changes of dirty animations and removes completed ones
        // TODO: optimize
        var removedNodes: [DOM.Node] = []
        for (node, animation) in runningAnimations {
            animation.applyChanges(context: &context)
            if animation.isCompleted {
                removedNodes.append(node)
            }
        }

        for node in removedNodes {
            runningAnimations.removeValue(forKey: node)
        }

        logTrace("running animations: \(runningAnimations.count)")
    }
}

private extension FLIPScheduler {

    enum NodeLayoutAction {
        case none
        case moveAbsolute(rect: DOM.Rect)
    }

    struct PreviousStyleValues {
        var position: String
        var left: String
        var top: String
        var width: String
        var height: String
    }

    struct ScheduledNode {
        var transaction: Transaction
        var geometry: NodeGeometry
        var containerNode: DOM.Node?
        var layoutAction: NodeLayoutAction = .none
    }

    struct NodeGeometry {
        var boundingClientRect: DOM.Rect
        var parentRect: DOM.Rect?

        var width: Double
        var height: Double

        var scopedCoordinates: (x: Double, y: Double) {
            if let parentRect = parentRect {
                return (x: boundingClientRect.x - parentRect.x, y: boundingClientRect.y - parentRect.y)
            } else {
                return (x: boundingClientRect.x, y: boundingClientRect.y)
            }
        }
        // NOTE: extend with transform/rotate or other stuff
    }

    final class GeometryAnimation {
        var translation: FLIPAnimation<CSSTransform.Translation>?
        var width: FLIPAnimation<CSSWidth>?
        var height: FLIPAnimation<CSSHeight>?

        var isCompleted: Bool {
            translation == nil && width == nil && height == nil
        }

        init(node: DOM.Node, first: NodeGeometry, last: NodeGeometry, transaction: Transaction, frameTime: Double) {
            let firstCoordinates = first.scopedCoordinates
            let lastCoordinates = last.scopedCoordinates
            let dx = firstCoordinates.x - lastCoordinates.x
            let dy = firstCoordinates.y - lastCoordinates.y
            let dw = last.width - first.width
            let dh = last.height - first.height

            // TODO: implement scale animation as option

            if shouldAnimateTranslation(dx, dy) {
                self.translation = FLIPAnimation<CSSTransform.Translation>(
                    node: node,
                    first: CSSTransform.Translation(x: Float(dx), y: Float(dy)),
                    last: CSSTransform.Translation(x: 0, y: 0),
                    transaction: transaction,
                    frameTime: frameTime
                )
            }

            if shouldAnimateSizeDelta(dw) {
                self.width = FLIPAnimation<CSSWidth>(
                    node: node,
                    first: CSSWidth(value: first.width),
                    last: CSSWidth(value: last.width),
                    transaction: transaction,
                    frameTime: frameTime
                )
            }

            if shouldAnimateSizeDelta(dh) {
                self.height = FLIPAnimation<CSSHeight>(
                    node: node,
                    first: CSSHeight(value: first.height),
                    last: CSSHeight(value: last.height),
                    transaction: transaction,
                    frameTime: frameTime
                )
            }
        }

        func cancelAll() {
            logTrace("cancelling all animations for node")
            self.translation?.cancel()
            self.width?.cancel()
            self.height?.cancel()

            self.translation = nil
            self.width = nil
            self.height = nil
        }

        func applyChanges(context: inout _CommitContext) {
            translation?.commit(context: &context)
            width?.commit(context: &context)
            height?.commit(context: &context)

            if translation?.isCompleted == true {
                self.translation = nil
            }
            if width?.isCompleted == true {
                self.width = nil
            }
            if height?.isCompleted == true {
                self.height = nil
            }
        }
    }

}

fileprivate extension FLIPScheduler {
    func getNodeGeometry(_ node: DOM.Node, scopedTo parentRect: DOM.Rect? = nil) -> NodeGeometry {
        let rect = dom.getBoundingClientRect(node)

        // TODO: figure out how to do this in embedded
        // let computedStyle = dom.makeComputedStyleAccessor(node)

        // // Parse width and height from computed styles (e.g., "100px" -> 100.0)
        // let widthString = computedStyle.get("width")
        // let heightString = computedStyle.get("height")

        // logTrace("width: \(widthString), height: \(heightString)")

        // let width = parseCSSLength(widthString) ?? rect.width
        // let height = parseCSSLength(heightString) ?? rect.height

        let width = rect.width
        let height = rect.height

        return NodeGeometry(
            boundingClientRect: rect,
            parentRect: parentRect,
            width: width,
            height: height
        )
    }

    func parseCSSLength(_ value: String) -> Double? {
        nil

        // guard !value.isEmpty, value != "auto" else { return nil }
        // // Remove "px" suffix and parse as Double
        // if value.hasSuffix("px") {
        //     let numberString = String(value.dropLast(2))
        //     return Double(numberString)
        // }
        // return nil
    }
}

private func shouldAnimateSizeDelta(_ ds: Double) -> Bool {
    ds > 1 || ds < -1
}

private func shouldAnimateTranslation(_ dx: Double, _ dy: Double) -> Bool {
    dx > 1 || dx < -1 || dy > 1 || dy < -1
}

extension DOM.Interactor {
    func needsAbsolutePositioning(_ node: DOM.Node) -> Bool {
        let computedStyle = makeComputedStyleAccessor(node)
        let position = computedStyle.get("position")
        return position != "absolute" && position != "fixed"
    }

    func getAbsolutePositionCoordinates(_ node: DOM.Node) -> DOM.Rect {
        let nodeRect = getBoundingClientRect(node)

        if let positionedAncestor = getOffsetParent(node) {
            logTrace("positioned ancestor: \(positionedAncestor)")
            let ancestorRect = getBoundingClientRect(positionedAncestor)
            logTrace("ancestor rect: \(ancestorRect)")
            return DOM.Rect(x: nodeRect.x - ancestorRect.x, y: nodeRect.y - ancestorRect.y, width: nodeRect.width, height: nodeRect.height)
        }

        return nodeRect
    }
}
