# Reactive Wasm Web-Components with Embedded Swift 

Based on [Elementary.](https://github.com/sliemeobn/elementary)

Check out the example app: https://sliemeobn.github.io/elementary-dom/

## Highly experimental, do not use.

Developed with dev snapshot of swift and matching wasm SDK.

## Things to figure out

- embedded-port of Observation
- identity system and list-diffing
- lifecycle events and proper "unmounting" (currently node are just "dropped")
- @State system (maybe that help with isolation?)
- typed event handlers
- "model-bindings" for inputs (ie: bind a @Binding<String> to a textbox, or bind a @Binding<Bool> on a check box)
- @Environment system
- preference system (ie: bubbling up values)
- isolation and @MainActor stuff for reusable types (server-side-rendering and client apps)
- decide whether the current idea of `Views` flattening themselves into renderalbe types is even necessary, or if views should just "apply" themselves into the reconciler - might be a bit messier, but maybe faster and more flexible

## Command Graveyard

```
swift build --swift-sdk DEVELOPMENT-SNAPSHOT-2024-09-20-a-wasm32-unknown-wasi -Xswiftc -static-stdlib -c release -Xswiftc -wmo -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor -Xlinker --export-if-defined=__main_argc_argv

python3 -m http.server -d TestPage
```
