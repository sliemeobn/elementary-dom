import JavaScriptKit

public struct MountingContainer: Sendable {
    enum Value: Sendable {
        case body
        case cssSelector(String)
    }

    let value: Value

    public static var body: MountingContainer {
        MountingContainer(value: .body)
    }

    public static func cssSelector(_ selector: String) -> MountingContainer {
        MountingContainer(value: .cssSelector(selector))
    }

    fileprivate func findDOMNode() -> JSObject? {
        switch value {
        case .body:
            return JSObject.global.document.body.object
        case let .cssSelector(selector):
            return JSObject.global.document.querySelector(selector).object
        }
    }
}

public extension View {
    // TODO: maybe return some kind of handle to ... unmount?
    consuming func mount(in element: MountingContainer) {
        guard let domNode = element.findDOMNode() else {
            // TODO: throw error?
            print("Mounting failed: no DOM node found for \(element)")
            return
        }

        mount(inNode: domNode)
    }

    consuming func mount(inNode domNode: JSObject) {
        _ = App(dom: JSKitDOMInteractor(), domRoot: DOM.Node(domNode), appView: self)
    }
}
