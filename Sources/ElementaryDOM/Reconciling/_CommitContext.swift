public struct _CommitContext: ~Copyable {
    public let dom: any DOM.Interactor
    public let currentFrameTime: Double

    init(dom: any DOM.Interactor, currentFrameTime: Double) {
        self.dom = dom
        self.currentFrameTime = currentFrameTime
    }
}
