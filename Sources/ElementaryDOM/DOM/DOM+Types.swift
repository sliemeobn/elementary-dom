extension DOM {
    public struct Node {
        let ref: AnyObject
    }

    public struct Event {
        let ref: AnyObject
    }

    public struct EventSink {
        let ref: AnyObject
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
}
