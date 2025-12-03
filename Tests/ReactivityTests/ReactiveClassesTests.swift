import Reactivity
import Synchronization
import Testing

@Suite
struct ReactiveClassesTests {
    @Test
    func tracksChanges() {
        let foo = Foo()
        let tracker = ChangeTracker()

        withReactiveTracking {
            _ = foo.one
        } onChange: {
            tracker.hasChanged = true
        }

        foo.two = "test"
        #expect(!tracker.hasChanged)
        foo.one = "test"
        #expect(tracker.hasChanged)
    }

    @Test
    func tracksChangesInParellel() async {
        await withTaskGroup { group in
            for _ in 0..<1000 {
                group.addTask {
                    let foo = Foo()
                    let tracker = ChangeTracker()
                    await Task.yield()
                    withReactiveTracking {
                        _ = foo.one
                    } onChange: {
                        tracker.hasChanged = true
                    }
                    await Task.yield()
                    foo.two = "test"
                    await Task.yield()
                    #expect(!tracker.hasChanged)
                    await Task.yield()
                    foo.one = "test"
                    #expect(tracker.hasChanged)
                }
            }
        }

    }
}

final class ChangeTracker: Sendable {
    private let _hasChanged = Atomic(false)

    var hasChanged: Bool {
        get {
            _hasChanged.load(ordering: .relaxed)
        }
        set {
            _hasChanged.store(newValue, ordering: .relaxed)
        }
    }
}

@Reactive
class Foo {
    var one: String = ""
    var two: String = ""
}
