extension DOM {
    public struct Node: Hashable {
        let ref: AnyObject

        public func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(ref))
        }

        public static func == (lhs: Node, rhs: Node) -> Bool {
            ObjectIdentifier(lhs.ref) == ObjectIdentifier(rhs.ref)
        }
    }

    public struct Event {
        let ref: AnyObject
    }

    public struct EventSink {
        let ref: AnyObject
    }

    public struct Rect: Equatable {
        public var x: Double
        public var y: Double
        public var width: Double
        public var height: Double

        public init(x: Double, y: Double, width: Double, height: Double) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }

    public enum PropertyValue {
        case string(String)
        case number(Double)
        case boolean(Bool)
        case stringArray([String])
        case null
        case undefined
    }

    public struct PropertyAccessor {
        let _get: () -> PropertyValue?
        let _set: (PropertyValue) -> Void

        init(
            get: @escaping () -> PropertyValue?,
            set: @escaping (PropertyValue) -> Void
        ) {
            self._get = get
            self._set = set
        }

        func get() -> PropertyValue? {
            _get()
        }

        func set(_ value: PropertyValue) {
            _set(value)
        }
    }

    public struct StyleAccessor {
        let _get: () -> String
        let _set: (String) -> Void

        init(
            get: @escaping () -> String,
            set: @escaping (String) -> Void
        ) {
            self._get = get
            self._set = set
        }

        func get() -> String {
            _get()
        }

        func set(_ value: String) {
            _set(value)
        }
    }

    public struct ComputedStyleAccessor {
        let _get: (String) -> String

        init(
            get: @escaping (String) -> String
        ) {
            self._get = get
        }

        func get(_ cssName: String) -> String {
            _get(cssName)
        }
    }
}
