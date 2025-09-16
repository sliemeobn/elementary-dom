#if os(WASI)
@_exported import func WASILibc.sqrt
@_exported import func WASILibc.cos
@_exported import func WASILibc.sin
@_exported import func WASILibc.pow
@_exported import func WASILibc.exp
#elseif canImport(FoundationEssentials)
@_exported import func FoundationEssentials.sqrt
@_exported import func FoundationEssentials.cos
@_exported import func FoundationEssentials.sin
@_exported import func FoundationEssentials.pow
@_exported import func FoundationEssentials.exp
#elseif canImport(Foundation)
@_exported import func Foundation.sqrt
@_exported import func Foundation.cos
@_exported import func Foundation.sin
@_exported import func Foundation.pow
@_exported import func Foundation.exp
#else
//fatalError("Unsupported platform")
#endif
