// TODO: move to a better place, maybe use a span with lifecycle stuff
public struct ContainerLayoutPass: ~Copyable {
    var entries: [Entry]
    private(set) var isAllRemovals: Bool = true
    private(set) var isAllAdditions: Bool = true

    var canBatchReplace: Bool {
        (isAllRemovals || isAllAdditions) && entries.count > 1
    }

    init() {
        entries = []
    }

    mutating func append(_ entry: Entry) {
        entries.append(entry)
        isAllAdditions = isAllAdditions && entry.kind == .added
        isAllRemovals = isAllRemovals && entry.kind == .removed
    }

    struct Entry {
        enum NodeType {
            case element
            case text
        }

        enum Status {
            case unchanged
            case added
            case leaving  // TODO: something can be leaving and moved....
            case removed
            case moved
        }

        let kind: Status
        let reference: DOM.Node
        let type: NodeType
    }
}
