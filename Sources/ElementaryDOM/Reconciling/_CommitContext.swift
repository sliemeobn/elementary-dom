public struct _CommitContext: ~Copyable {
    let dom: any DOM.Interactor
    let scheduler: Scheduler
    let currentFrameTime: Double

    init(dom: any DOM.Interactor, scheduler: Scheduler, currentFrameTime: Double) {
        self.dom = dom
        self.currentFrameTime = currentFrameTime
        self.scheduler = scheduler
    }
}
