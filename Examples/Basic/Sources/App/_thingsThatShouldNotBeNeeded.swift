import JavaScriptKit

// NOTE: reference symbols for wasm linking (https://github.com/swiftlang/swift/issues/77812)
#if hasFeature(Embedded)
func _i_need_to_be_here_for_wasm_exports_to_work() {
    _ = _swjs_library_features
    _ = _swjs_call_host_function
    _ = _swjs_free_host_function
}
#endif
