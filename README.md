# Reactive Web Components with Embedded Swift

Create client-side web apps in Swift that weigh less than 200 kB.

**[Check out the "Swiftle" demo app!](/Examples/Swiftle/)**

## 🚧 Experimental 🚧
Based on the [swift.org WebAssembly SDKs](https://forums.swift.org/t/swift-sdks-for-webassembly-now-available-on-swift-org/80405), [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit), and [Elementary](https://github.com/sliemeobn/elementary).

For embedded builds, a recent main or 6.2 snapshot with matching *Swift SDKs for WebAssembly* from [swift.org](https://www.swift.org/install) is required.

## Things to figure out

- ~~identity system and list-diffing~~
- ~~lifecycle events and proper "unmounting" (currently nodes are just "dropped")~~
- ~~@State system~~
- ~~typed event handlers~~
- ~~@Environment system~~
- ~~dependencies on versioned packages (i.e., build without unsafe flags)~~
- ~~fix DOM not child-diffing to preserve animations/nodes (the current solution based on `replaceChildren` will not work, it seems)~~
- "model-bindings" for inputs (i.e., bind a @Binding<String> to a text box, or bind a @Binding<Bool> to a checkbox)
- maybe conditionally support @Observable for non-embedded builds?
- transitions and animations (CSS-based)
- figure out why `@Environment` with optional `ReactiveObject` does not build in embedded
- proper unit testing (once APIs firm up a bit more)
- preference system (i.e., bubbling up values)
- embedded-friendly Browser APIs (Storage, History, maybe in swiftwasm package with new JavaScriptKit macros)
- ~~think about how to deal with the lack of `Codable` in embedded (wait for new serialization macros)~~
- ~~make printing work without WASI (maybe pipe putchar through to JavaScript?)~~
- isolation and @MainActor stuff for reusable types (server-side-rendering and client apps)
- ~~decide whether the current idea of `Views` flattening themselves into renderable types is even necessary, or if views should just "apply" themselves into the reconciler - might be a bit messier, but maybe faster and more flexible~~

### Embedded Swift for WASM waitlist

- ~~simple build with SwiftPM (wasm-ld)~~
- ~~\_Concurrency module (Task)~~
- Codable 2.0 (we need JSON handling for embedded, on [the horizon](https://forums.swift.org/t/the-future-of-serialization-deserialization-apis/78585))
- Synchronization (Mutex)

## License and Derived Code

This package is generally licensed as [Apache 2](LICENSE).

The `Rectivity` module is inspired by the Swift stdlib's `Observation` framework, and code in `ReactivityMacros` is directly derived from it ([source](https://github.com/swiftlang/swift/tree/main/lib/Macros/Sources/ObservationMacros)).
Find a copy of the Swift.org open source project license [here](LICENSE-swift_org.md).

This project includes binaries from the [wasi-libc project](https://github.com/WebAssembly/wasi-libc), which is licensed under the Apache License 2.0 with LLVM Exceptions.