# Reactive Web Components with Embedded Swift

Create client-side web apps in Swift that weigh less than 200 kB.

**[Check out the "Swiftle" demo app!](/Examples/Swiftle/)**

## 🚧 Work In Progress 🚧
Based on the [swift.org WebAssembly SDKs](https://forums.swift.org/t/swift-sdks-for-webassembly-now-available-on-swift-org/80405), [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit), and [Elementary](https://github.com/sliemeobn/elementary).

For embedded builds, a recent main or 6.2 snapshot with matching *Swift SDKs for WebAssembly* from [swift.org](https://www.swift.org/install) is required.

> [!IMPORTANT]
> ElementaryDOM is a passion project under active development.\
> Expect sharp edges, APIs may change, and things may break while I balance performance, ergonomics, and feature set.
>
> Nothing is stopping us from having a viable, fully featured, client-side web frontend library powered by Swift.
> 
> If you want to see this come to life, sponsorship is sincerely appreciated 🙏\
> [![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/sliemeobn)

## Things to figure out

- ~~identity system and list-diffing~~
- ~~lifecycle events and proper "unmounting" (currently nodes are just "dropped")~~
- ~~@State system~~
- ~~typed event handlers~~
- ~~@Environment system~~
- ~~dependencies on versioned packages (i.e., build without unsafe flags)~~
- ~~fix DOM not child-diffing to preserve animations/nodes (the current solution based on `replaceChildren` will not work, it seems)~~
- "model-bindings" for inputs (i.e., bind a @Binding<String> to a text box, or bind a @Binding<Bool> to a checkbox)
- transitions and animations (ideally CSS-based, probably svelte-like custom easing functions applied through WAAPI)
- proper unit testing (once APIs firm up a bit more)
- split out JavaScriptKit stuff in separate module to contain spread, maybe one day we can switch to faster interop somehow
- add basic docs, a good intro readme, and push a 0.1 out the door! (probably best to wait for Swift 6.2 to drop)
- a router implementation (probably in extra module?)
- maybe conditionally support @Observable for non-embedded builds?
- figure out why `@Environment` with optional `ReactiveObject` does not build in embedded
- preference system (i.e., bubbling up values)
- embedded-friendly Browser APIs (Storage, History, maybe in swiftwasm package with new JavaScriptKit macros)
- ~~think about how to deal with the lack of `Codable` in embedded (wait for new serialization macros)~~
- ~~make printing work without WASI (maybe pipe putchar through to JavaScript?)~~
- isolation and @MainActor stuff for reusable types (server-side rendering and client apps - probably never quite possible to have same types render "multi-threaded" server side and stay single-threaded client side....)
- ~~decide whether the current idea of `Views` flattening themselves into renderable types is even necessary, or if views should just "apply" themselves into the reconciler - might be a bit messier, but maybe faster and more flexible~~
- move all elementary repos under one project roof and use a traits-based, single "ElementaryUI" top-level package (or similar)

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