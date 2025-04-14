import JavaScriptKit

// NOTE: reference symbols for wasm linking (https://github.com/swiftlang/swift/issues/77812)
#if hasFeature(Embedded)
func _i_need_to_be_here_for_wasm_exports_to_work() {
    _ = _swjs_library_features
    _ = _swjs_call_host_function
    _ = _swjs_free_host_function
}

// what could go wrong? yolo
@_silgen_name("swift_float64ToString")
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
    var digits = [UInt8]()

    repeat {
        digits.append(UInt8(temp % 10) + 48)  // ASCII '0' is 48
        temp /= 10
    } while temp > 0

    for digit in digits.reversed() {
        if index > maxIndex { return UInt64(index) }
        buffer[index] = digit
        index += 1
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

extension String {
    // native string comparison would require unicode stuff
    @inline(__always)
    func utf8Equals(_ other: borrowing String) -> Bool {
        utf8.elementsEqual(other.utf8)
    }
}
