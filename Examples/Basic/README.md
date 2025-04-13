# Basic example

Test project that builds for Embedded and "full Swift"

## Full Swift (6.1)

using Swift WASM SDK, JavaScriptKit js plugin
https://book.swiftwasm.org/getting-started/setup.html

```sh
# requires Swift SDK installed
./build-wasi.sh
npx serve Public
```

```sh
# Debug build + watch mode
./watch.sh
```

## Embedded Swift (main)
Requires a recent main snapshot. (but no WASM SDK)

```sh
# Tested with main-snapshot-2025-03-28
./build-embedded.sh
npx serve Public
```
