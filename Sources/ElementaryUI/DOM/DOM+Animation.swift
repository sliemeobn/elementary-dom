extension DOM {
    struct Animation {
        let _cancel: () -> Void
        let _update: (KeyframeEffect) -> Void

        func cancel() {
            _cancel()
        }

        func update(_ effect: KeyframeEffect) {
            _update(effect)
        }
    }
}

extension DOM.Animation {
    enum CompositeOperation: Sendable {
        case replace
        case add
        case accumulate
    }

    struct KeyframeEffect {
        var property: String
        var values: [String]
        var duration: Int  // milliseconds
        var composite: CompositeOperation
    }
}
