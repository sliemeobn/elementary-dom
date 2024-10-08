// this is just a super quick and fast patch to try out updated views, this needs a bit of work and thiking

var closures: [() -> Void] = []

func withObservationTracking<T>(_ body: () -> T, onChange: @escaping () -> Void) -> T {
    closures.append(onChange)
    return body()
}

public func _future_change_tracking_manual_for_now() {
    var workingSet: [() -> Void] = []
    swap(&workingSet, &closures)
    for closure in workingSet {
        closure()
    }
}
