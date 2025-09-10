// FIXME: embedded - create issue and check with main
// we need to force addition of types that are present in unused enum cases -> otherwise it crashes the compiler (6.2 at least)
#if hasFeature(Embedded)
internal var __omg_this_was_annoying_I_am_false: Bool = false
#endif

// FIXME: embedded - remove once https://github.com/swiftlang/swift/issues/83460 lands
#if hasFeature(Embedded)
@_silgen_name("swift_float64ToString")
@_noAllocation
public func _swift_float64ToString(
    _ buffer: UnsafeMutablePointer<UInt8>,
    _ bufferLength: UInt,
    _ value: Double,
    _ isDebug: Bool
) -> UInt64 {
    var value = value
    var index = 0
    let maxIndex = Int(bufferLength) - 1

    if value < 0 {
        if index > maxIndex { return 0 }
        buffer[index] = 45  // '-'
        index += 1
        value = -value
    }

    let integerPart = Int(value)
    var temp = integerPart
    let start = index
    if temp == 0 {
        if index > maxIndex { return UInt64(index) }
        buffer[index] = 48  // '0'
        index += 1
    } else {
        while temp > 0 {
            if index > maxIndex { return UInt64(index) }
            let digit = UInt8(temp % 10) + 48  // ASCII '0' is 48
            buffer[index] = digit
            index += 1
            temp /= 10
        }
        // reverse the integer digits written in place
        var i = start
        var j = index - 1
        while i < j {
            let t = buffer[i]
            buffer[i] = buffer[j]
            buffer[j] = t
            i += 1
            j -= 1
        }
    }

    let fractionalPart = value - Double(integerPart)
    if fractionalPart > 0 {
        if index > maxIndex { return UInt64(index) }
        buffer[index] = 46  // '.'
        index += 1

        var remaining = fractionalPart
        var decimalPlaces = 0
        var hasNonZeroDigit = false

        while decimalPlaces < 5 && index <= maxIndex {
            remaining *= 10
            let digit = Int(remaining)
            buffer[index] = UInt8(digit) + 48
            index += 1
            remaining -= Double(digit)
            decimalPlaces += 1
            if digit != 0 {
                hasNonZeroDigit = true
            }
        }

        // Check if we need to round up
        if index <= maxIndex {
            remaining *= 10
            let nextDigit = Int(remaining)
            if nextDigit >= 5 {
                // Round up the last digit
                var i = index - 1
                while i >= 0 {
                    if buffer[i] == 46 {  // skip the decimal point
                        i -= 1
                        continue
                    }
                    if buffer[i] < 57 {  // '9'
                        buffer[i] += 1
                        break
                    } else {
                        buffer[i] = 48  // '0'
                        i -= 1
                    }
                }
            }
        }

        // Only remove trailing zeros if there are non-zero digits after the decimal point
        if hasNonZeroDigit {
            while index > 0 && buffer[index - 1] == 48 {  // '0'
                index -= 1
            }
            if index > 0 && buffer[index - 1] == 46 {  // '.'
                index -= 1
            }
        }
    }

    return UInt64(index)
}
#endif
