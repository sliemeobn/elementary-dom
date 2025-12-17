# ElementaryUI Browser Runtime

Bundled JavaScriptKit + WASI bootstrap for running ElementaryUI WebAssembly applications in the browser.

## What is this?

This package provides JavaScript glue code to run ElementaryUI WebAssembly applications in the browser.

> [!IMPORTANT]
> If you are not targeting an ElementaryUI Vite setup, you should use the JavaScriptKit `swift package js` plugin instead.

- **JavaScriptKit Runtime** - Swift-to-JavaScript interop layer (vendored from [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit))
- **WASI Bootstrap** - Minimal WASI setup for browser environments ([@bjorn3/browser_wasi_shim](https://github.com/bjorn3/browser_wasi_shim))

## Usage
```ts
import { runApplication } from "elementary-ui-browser-runtime";

await runApplication(async (imports) => {
  const { instance } = await WebAssembly.instantiateStreaming(
    fetch("./App.wasm"),
    imports
  );
  return instance;
});
```

## License

This package contains code under multiple licenses. See [LICENSE](LICENSE.md) for details.