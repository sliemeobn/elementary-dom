public struct ReactivityRegistrar: Sendable {
  private final class _Lifetime: Sendable {
    let tracker = ReactivityTracker()

    init() {}

    deinit {
      tracker.cancelAll()
    }
  }

  private var lifetime = _Lifetime()

  var tracker: ReactivityTracker {
    return lifetime.tracker
  }

  public init() {}

  public func access(_ property: PropertyID) {
    if let trackingPtr = _ThreadLocal.value?
      .assumingMemoryBound(to: ReactivePropertyAccessList?.self)
    {
      if trackingPtr.pointee == nil {
        trackingPtr.pointee = ReactivePropertyAccessList()
      }
      trackingPtr.pointee?.add(property, tracker: tracker)
    }
  }

  public func willSet(_ property: PropertyID) {
    tracker.willSet(property: property)
  }

  public func didSet(_ property: PropertyID) {
    tracker.didSet(property: property)
  }
}

extension ReactivityRegistrar: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool { true }
  public func hash(into hasher: inout Hasher) {}
}

public protocol ReactiveObject: AnyObject {
  static var _$typeID: PropertyID { get }
}
