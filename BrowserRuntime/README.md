# ElementaryUI Browser Runtime

Bundled JavaScriptKit + WASI bootstrap for running ElementaryUI WebAssembly applications in the browser.

## What is this?

This package provides a bit of glue code to easily run.

> [!IMPORTANT]
> If you are not targetting an ElementaryUI vite setup, you should probably use the `swift package js` plugin from JavaScriptKit instead.

- **JavaScriptKit Runtime** - Swift-to-JavaScript interop layer (vendored from [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit))
- **WASI Shim** - Minimal WASI implementation for browser environments

## Why does this exist?

ElementaryUI applications compile to WebAssembly, but WASM needs JavaScript to:
1. Load and instantiate the `.wasm` module
2. Provide import functions for JavaScript interop
3. Provide WASI syscalls (file I/O, environment access, etc.)

This package bundles everything you need in a single, version-locked runtime that's distributed via Swift Package Manager.

## License

This package contains code under multiple licenses. see [LICENSE](LICENSE.md)