import JavaScriptKit

// NOTE: it seems the embedded tree shaker gets rid of these exports if they are not used somewhere
#if hasFeature(Embedded)
    func _i_need_to_be_here_for_wasm_exports_to_work() {
        _ = _swjs_library_features
        _ = _swjs_call_host_function
        _ = _swjs_free_host_function
    }
#endif

extension String {
    // native string comparison would require unicode stuff
    @inline(__always)
    func utf8Equals(_ other: borrowing String) -> Bool {
        utf8.elementsEqual(other.utf8)
    }
}
