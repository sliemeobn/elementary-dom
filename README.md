# Reactive Wasm Web-Components with Embedded Swift

Based on [Elementary.](https://github.com/sliemeobn/elementary)

Check out the example app: https://sliemeobn.github.io/elementary-dom/

## Highly experimental, do not use.

Developed with a recent snapshot of swift. No WASM/WASI SDK required when built for Embedded (see [Examples](Examples))

## Things to figure out

- identity system and list-diffing
- ~~lifecycle events and proper "unmounting" (currently node are just "dropped")~~
- ~~@State system~~
- ~~typed event handlers~~
- @Environment system
- "model-bindings" for inputs (ie: bind a @Binding<String> to a textbox, or bind a @Binding<Bool> on a check box)
- preference system (ie: bubbling up values)
- proper unit testing (once APIs firm up a bit more)
- Browser APIs (Storage, History)
- make printing work without WASI (maybe pipe putchar through to javascript?)
- isolation and @MainActor stuff for reusable types (server-side-rendering and client apps)
- decide whether the current idea of `Views` flattening themselves into renderalbe types is even necessary, or if views should just "apply" themselves into the reconciler - might be a bit messier, but maybe faster and more flexible

### Embedded Swift for WASM waitlist

- \_Concurrency module (Task)
- Synchronization (Mutex)
- Codable (we probably need another way to JSON-ify things)

## License and Derived Code

This package is generally licensed as [Apache 2](LICENSE).

The `Rectivity` module is inspired by the Swift stdlib's `Observation` framework, and code in `ReactivityMacros` is directly derived from it ([source](https://github.com/swiftlang/swift/tree/main/lib/Macros/Sources/ObservationMacros)).
Find a copy of the Swift.org open source project license [here](LICENSE-swift_org.md).
