public struct _CommitContext: ~Copyable {
    let dom: any DOM.Interactor
    let currentFrameTime: Double

    private var prePaintActions: [() -> Void] = []
    private var postPaintActions: [() -> Void] = []

    init(dom: any DOM.Interactor, currentFrameTime: Double) {
        self.dom = dom
        self.currentFrameTime = currentFrameTime
    }

    mutating func addPrePaintAction(_ action: @escaping () -> Void) {
        prePaintActions.append(action)
    }

    mutating func addPostPaintAction(_ action: @escaping () -> Void) {
        postPaintActions.append(action)
    }

    consuming func drain() {
        for action in prePaintActions {
            action()
        }
        prePaintActions.removeAll()

        // TODO: make this better, clearer scheduling
        dom.runNext { [postPaintActions] in
            for action in consume postPaintActions {
                action()
            }
        }
    }
}
