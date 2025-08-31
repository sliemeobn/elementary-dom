import ElementaryDOM

final class RenderTracker {
    private(set) var calls: [String] = []

    init() {
        print("RenderTracker init")
    }

    func record(_ name: String) {
        calls.append(name)
    }

    func reset() {
        calls.removeAll()
    }
}

extension EnvironmentValues {
    @Entry var tracker: RenderTracker
}

@View
struct Track<Wrapped: View> {
    @Environment(#Key(\.tracker)) var tracker
    var name: String
    @HTMLBuilder let wrapped: Wrapped

    var content: some View {
        let _ = tracker.record(name)
        wrapped
    }
}
