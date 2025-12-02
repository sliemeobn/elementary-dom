final class FLIPScheduler {
    private var dom: any DOM.Interactor

    // NOTE: extend this to support css properties as well - for now it is always the bounding rect stuff
    private var scheduledAnimations: [DOM.Node: ScheduledNode] = [:]
    private var runningAnimations: [DOM.Node: GeometryAnimation] = [:]

    init(dom: any DOM.Interactor) {
        self.dom = dom
    }

    func scheduleAnimationOf(_ nodes: [DOM.Node], inParent parentNode: DOM.Node, context: inout _RenderContext) {
        let parentRect = dom.getBoundingClientRect(parentNode)
        for node in nodes {
            // TODO: we should probably optimize for repeated call of same not to avoid re-calculating the scoped rect
            // currently: last write wins
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
        runningAnimations.removeValue(forKey: node)
    }

    func markAsLeaving(_ node: DOM.Node) {
        // TODO: set absolut
    }

    func commitScheduledAnimations(context: inout _CommitContext) {
        logTrace("committing scheduled FLIP animations")

        // undo all running animations that are effected
        for node in scheduledAnimations.keys {
            // TODO: find a good way to preserve velocities of redirected animations
            runningAnimations[node]?.cancelAll()
        }

        let parentRects: [DOM.Node: DOM.Rect] = Dictionary(
            uniqueKeysWithValues: Set(scheduledAnimations.values.compactMap { $0.containerNode })
                .compactMap { node -> (DOM.Node, DOM.Rect)? in
                    (node, dom.getBoundingClientRect(node))
                }
        )

        // measure all LAST states
        for (node, animation) in scheduledAnimations {
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

        // apply all changes
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
    struct ScheduledNode {
        let transaction: Transaction
        let geometry: NodeGeometry
        let containerNode: DOM.Node?
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
        // NOTE: extend with transform of other stuff
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

            // TODO: implement scale animation

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

final class FLIPAnimation<Value: CSSAnimatable> {
    private var node: DOM.Node
    private var animatedValue: AnimatedValue<Value>
    private var domAnimation: DOM.Animation?
    private var isDirty: Bool

    var isCompleted: Bool {
        !animatedValue.isAnimating
    }

    init(node: DOM.Node, first: Value, last: Value, transaction: Transaction, frameTime: Double) {
        self.node = node
        self.animatedValue = AnimatedValue(value: first)

        _ = self.animatedValue.setValueAndReturnIfAnimationWasStarted(last, transaction: transaction, frameTime: frameTime)
        isDirty = true
    }

    func cancel() {
        domAnimation?.cancel()
        domAnimation = nil
        animatedValue.cancelAnimation()
    }

    func commit(context: inout _CommitContext) {
        if isDirty {
            logTrace("committing dirty animation \(Value.CSSValue.styleKey)")
            isDirty = false
            let value = animatedValue.nextCSSAnimationValue(frameTime: context.currentFrameTime)

            switch value {
            case .single(_):
                logTrace("cancelling animation \(Value.CSSValue.styleKey)")
                domAnimation?.cancel()
                domAnimation = nil
            case .animated(let track):
                let effect = DOM.Animation.KeyframeEffect(.animated(track), isFirst: false)
                if let domAnimation = domAnimation {
                    domAnimation.update(effect)
                } else {
                    // TODO: find a better way to schedule a callback here
                    domAnimation = context.dom.animateElement(node, effect) { [scheduler = context.scheduler] in
                        scheduler.registerAnimation(
                            AnyAnimatable { context in
                                logTrace("CSS animation of \(Value.CSSValue.styleKey) completed, marking dirty")
                                self.animatedValue.progressToTime(context.currentFrameTime)
                                self.isDirty = true
                                // TODO: fix this nonsense
                                context.scheduler.addCommitAction(CommitAction { _ in })
                                return .completed
                            }
                        )
                    }
                }
            }
        }
    }
}

private func shouldAnimateSizeDelta(_ ds: Double) -> Bool {
    ds > 1 || ds < -1
}

private func shouldAnimateTranslation(_ dx: Double, _ dy: Double) -> Bool {
    dx > 1 || dx < -1 || dy > 1 || dy < -1
}
