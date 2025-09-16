//TODO: there must be a better way to do this
#if canImport(WASILibc)
@_exported import func WASILibc.sqrt
@_exported import func WASILibc.sqrtf
@_exported import func WASILibc.cos
@_exported import func WASILibc.sin
@_exported import func WASILibc.pow
@_exported import func WASILibc.exp
#elseif os(WASI) && hasFeature(Embedded)
@_extern(c) public func sqrt(_ x: Double) -> Double
@_extern(c) public func sqrtf(_ x: Float) -> Float
@_extern(c) public func cos(_ x: Double) -> Double
@_extern(c) public func sin(_ x: Double) -> Double
@_extern(c) public func pow(_ x: Double, _ y: Double) -> Double
@_extern(c) public func exp(_ x: Double) -> Double
#elseif canImport(FoundationEssentials)
@_exported import func FoundationEssentials.sqrt
@_exported import func FoundationEssentials.sqrtf
@_exported import func FoundationEssentials.cos
@_exported import func FoundationEssentials.sin
@_exported import func FoundationEssentials.pow
@_exported import func FoundationEssentials.exp
#elseif canImport(Foundation)
@_exported import func Foundation.sqrt
@_exported import func Foundation.sqrtf
@_exported import func Foundation.cos
@_exported import func Foundation.sin
@_exported import func Foundation.pow
@_exported import func Foundation.exp
#else
#fatalError("Unsupported platform")
#endif
