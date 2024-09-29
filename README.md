## Highly experimental, do not use.

Developed with dev snapshot of swift and matching wasm SDK.

```sh
# DEVELOPMENT-SNAPSHOT-2024-09-17-a
# run carton dev
swift package --disable-sandbox --swift-sdk DEVELOPMENT-SNAPSHOT-2024-09-20-a-wasm32-unknown-wasi carton-dev
```

## Things to figure out

- isolation and @MainActor stuff for reusable types (server-side-rendering and client apps)
- identity system and list-diffing
- lifecycle events and proper "unmounting" (currently node are just "dropped")
- @State system (maybe that help with isolation?)
- typed event handlers
- "model-bindings" for inputs (ie: bind a @Binding<String> to a textbox, or bind a @Binding<Bool> on a check box)
- @Environment system
- preference system (ie: bubbling up values)
- decide whether the current idea of `Views` flattening themselves into renderalbe types is even necessary, or if views should just "apply" themselves into the reconciler - might be a bit messier, but maybe faster and more flexible

...ideally all in a potentially embedded-friendly way (ie: no runtime reflection).
