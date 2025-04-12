import JavaScriptKit

// NOTE: all of this is because
// a) Tasks are not yet supported for embedded wasm (so we can't use `.task` with an async sequence)
// b) Combine obvsiously won't fly
// ideally, once tasks work in embedded wasm, we can replace this with an AsyncSequence

public protocol EventSource<Event> {
    associatedtype Event
    func subscribe(_ callback: @escaping (Event) -> Void) -> EventSourceSubscription
}

public struct EventSourceSubscription {
    let _cancel: () -> Void

    public func cancel() {
        _cancel()
    }
}

public extension View {
    func receive<Event>(_ eventSource: some EventSource<Event>, handler: @escaping (Event) -> Void) -> _LifecycleEventView<Self> {
        _LifecycleEventView(
            wrapped: self,
            listener: .onMountReturningCancelFunction {
                let subscription = eventSource.subscribe(handler)
                return subscription.cancel
            }
        )
    }
}

public enum GlobalDocument {
    static let document = JSObject.global.document
}

extension GlobalDocument {
    public static var onKeyDown: some EventSource<KeyboardEvent> {
        DOMEventSource(eventName: "keydown")
    }

    struct DOMEventSource<Event: DOMEvent>: EventSource {
        typealias Event = Event

        let eventName: String

        func subscribe(_ callback: @escaping (Event) -> Void) -> EventSourceSubscription {
            let closure = JSClosure { event in
                callback(Event(event[0].object!)!)
                return .undefined
            }

            _ = document.addEventListener(eventName, closure)

            return EventSourceSubscription {
                _ = document.removeEventListener(eventName, closure)
            }
        }
    }
}

//TODO: should be have some scope for this?
public var onAnimationFrame: some EventSource<AnimationFrameEvent> {
    AnimationFrameEventSource()
}

struct AnimationFrameEventSource: EventSource {
    typealias Event = AnimationFrameEvent
    static let _requestAnimationFrame = JSObject.global.requestAnimationFrame.function!
    static let _cancelAnimationFrame = JSObject.global.cancelAnimationFrame.function!

    func subscribe(_ callback: @escaping (AnimationFrameEvent) -> Void) -> EventSourceSubscription {
        var rafID: JSValue?
        var closure: JSClosure?

        closure = JSClosure { value in
            guard let closure else {
                return .undefined
            }
            rafID = AnimationFrameEventSource._requestAnimationFrame(closure)
            callback(AnimationFrameEvent(timestamp: value[0].number!))
            return .undefined
        }

        rafID = AnimationFrameEventSource._requestAnimationFrame(closure)

        return EventSourceSubscription {
            if let rafID = rafID {
                AnimationFrameEventSource._cancelAnimationFrame(rafID)
            }
            closure = nil
            rafID = nil
        }
    }
}

public struct AnimationFrameEvent {
    let timestamp: Double
}
