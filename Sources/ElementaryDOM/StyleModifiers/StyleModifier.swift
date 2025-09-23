// import Elementary

// // FIXME: CSSValue should not be needed, but there is embedded confusion around types, needs to be writte like this for now
// final class CSSAnimatedValueSource<Value, CSSValue> where Value: CSSAnimatable, CSSValue: CSSPropertyValue, Value.CSSValue == CSSValue {
//     var dependencies: DependencyTracker = .init()
//     var lastValue: Value

//     init(value: Value) {
//         self.lastValue = value

//         #if hasFeature(Embedded)
//         if __omg_this_was_annoying_I_am_false {
//             _ = self.makeLayer(target: MountedStyleModifier<CSSValue>(__unused: value.cssValue))
//         }
//         #endif
//     }

//     func updateValue(_ value: Value, _ context: inout _RenderContext) {
//         if value != lastValue {
//             lastValue = value
//             dependencies.invalidateAll(&context)
//         }
//     }

//     func makeLayer(target: MountedStyleModifier<CSSValue>) -> AnyCSSValueLayer<CSSValue> {
//         let layer = AnimatedLayer(source: self, target: target)
//         #if hasFeature(Embedded)
//         if __omg_this_was_annoying_I_am_false {
//             _ = layer.value
//             _ = layer.isDirty
//         }
//         #endif
//         return AnyCSSValueLayer(layer)
//     }

//     final class AnimatedLayer: Invalidateable {
//         var target: MountedStyleModifier<CSSValue>
//         let source: CSSAnimatedValueSource<Value, CSSValue>
//         var animatedValue: AnimatedValue<Value>
//         var isDirty: Bool = false

//         var value: CSSPropertyLayerValue<CSSValue>

//         init(source: CSSAnimatedValueSource<Value, CSSValue>, target: MountedStyleModifier<CSSValue>) {
//             self.target = target
//             self.source = source
//             self.animatedValue = AnimatedValue(value: source.lastValue)
//             self.value = .value(source.lastValue.cssValue)
//         }

//         func invalidate(_ context: inout _RenderContext) {
//             _ = animatedValue.setValueAndReturnIfAnimationWasStarted(source.lastValue, context: context)

//             if animatedValue.isAnimating {
//                 logWarning("animating not implemented")
//                 value = .value(animatedValue.presentation.cssValue)
//             } else {
//                 value = .value(animatedValue.presentation.cssValue)
//             }

//             isDirty = true
//             target.invalidate(&context)
//         }
//     }
// }

// struct AnyCSSValueLayerSource<CSSValue: CSSPropertyValue> {
//     private let _makeLayer: (MountedStyleModifier<CSSValue>) -> AnyCSSValueLayer<CSSValue>

//     init<Value>(_ source: CSSAnimatedValueSource<Value, CSSValue>) where Value: CSSAnimatable, Value.CSSValue == CSSValue {
//         self._makeLayer = source.makeLayer(target:)
//     }

//     func makeLayer(target: MountedStyleModifier<CSSValue>) -> AnyCSSValueLayer<CSSValue> {
//         _makeLayer(target)
//     }
// }

// struct AnyCSSValueLayer<Value: CSSPropertyValue> {
//     private let _getValue: () -> CSSPropertyLayerValue<Value>
//     private let _getIsDirty: () -> Bool
//     private let _setIsDirty: (Bool) -> Void

//     var isDirty: Bool {
//         get { _getIsDirty() }
//         nonmutating set { _setIsDirty(newValue) }
//     }
//     var value: CSSPropertyLayerValue<Value> {
//         get { _getValue() }
//     }

//     init<SourceValue>(_ layer: CSSAnimatedValueSource<SourceValue, Value>.AnimatedLayer)
//     where SourceValue: CSSAnimatable, SourceValue.CSSValue == Value {
//         self._getValue = { layer.value }
//         self._getIsDirty = { layer.isDirty }
//         self._setIsDirty = { layer.isDirty = $0 }
//     }
// }

// final class StyleModifier<SourcedValue>: DOMElementModifier, Invalidateable
// where SourcedValue: CSSPropertyValue {
//     typealias Value = AnyCSSValueLayerSource<SourcedValue>

//     let upstream: StyleModifier?
//     let layerNumber: Int
//     var tracker: DependencyTracker = .init()

//     var value: Value

//     init(value: consuming Value, upstream: borrowing DOMElementModifiers, _ context: inout _RenderContext) {
//         self.value = value
//         self.upstream = upstream[StyleModifier.key]
//         self.layerNumber = (self.upstream?.layerNumber ?? 0) + 1
//         self.upstream?.tracker.addDependency(self)
//     }

//     func updateValue(_ value: consuming Value, _ context: inout _RenderContext) {
//         self.value = value
//     }

//     func mount(_ node: DOM.Node, _ context: inout _CommitContext) -> AnyUnmountable {
//         AnyUnmountable(MountedStyleModifier(node, self, &context))
//     }

//     func invalidate(_ context: inout _RenderContext) {
//         self.tracker.invalidateAll(&context)
//     }
// }

// final class MountedStyleModifier<CSSValue: CSSPropertyValue>: Unmountable, Invalidateable {
//     let node: DOM.Node
//     let accessor: DOM.StyleAccessor
//     var layers: [AnyCSSValueLayer<CSSValue>]

//     var isDirty: Bool = false

//     init(__unused: CSSValue) {
//         self.node = DOM.Node(ref: Scheduler.init(dom: JSKitDOMInteractor(root: .global)))
//         self.accessor = DOM.StyleAccessor(get: { "" }, set: { _ in })
//         self.layers = []
//     }

//     init(_ node: DOM.Node, _ modifier: StyleModifier<CSSValue>, _ context: inout _CommitContext) {
//         self.node = node
//         self.accessor = context.dom.makeStyleAccessor(node, cssName: CSSValue.styleKey)
//         self.layers = []

//         layers.append(modifier.value.makeLayer(target: self))

//         var modifier = modifier
//         while let next = modifier.upstream {
//             layers.append(next.value.makeLayer(target: self))
//             modifier = next
//         }

//         self.layers.reverse()

//         updateDOMNode(&context)
//     }

//     func invalidate(_ context: inout _RenderContext) {

//         guard !isDirty else { return }
//         isDirty = true
//         context.scheduler.addNodeAction(CommitAction(run: updateDOMNode(_:)))
//     }

//     func updateDOMNode(_ context: inout _CommitContext) {
//         isDirty = false
//         if let combined = reduceCombinedSingleValue() {
//             accessor.set(combined.cssString)
//         } else {
//             // set up update animations
//             logWarning("animations not implemented")
//         }

//     }

//     func unmount(_ context: inout _CommitContext) {
//         layers.removeAll()
//     }
// }

// private extension MountedStyleModifier {
//     func reduceCombinedSingleValue() -> CSSValue? {
//         guard let first = layers.first?.value.singleValue else { return nil }
//         var combined = first
//         for layer in layers.dropFirst() {
//             guard let next = layer.value.singleValue else { return nil }
//             combined.combineWith(next)
//         }
//         return combined
//     }
// }
