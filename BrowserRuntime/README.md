# ElementaryUI Browser Runtime

Bundled JavaScriptKit + WASI bootstrap for running ElementaryUI WebAssembly applications in the browser.

## What is this?

This package provides a bit of glue code to easily run.

> [!IMPORTANT]
> If you are not targetting an ElementaryUI vite setup, you should probably use the `swift package js` plugin from JavaScriptKit instead.

- **JavaScriptKit Runtime** - Swift-to-JavaScript interop layer (vendored from [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit))
- **WASI Bootstrap** - A minimal WASI bootstrap for browser environments ([@bjorn3/browser_wasi_shim](https://github.com/bjorn3/browser_wasi_shim))

## License

This package contains code under multiple licenses. see [LICENSE](LICENSE.md)