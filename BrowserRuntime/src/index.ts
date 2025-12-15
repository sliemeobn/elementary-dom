import { createDefaultWASI } from "./wasi-shim";
import { SwiftRuntime } from "./vendored/javascriptkit/index.mjs";
import { createBridgeJSStubs } from "./bridgejs-shims";

type WasmInstanceInitializer = (
  importsObject?: WebAssembly.Imports
) => Promise<WebAssembly.Instance>;

// TODO: offer more customization entry-points (ie: BYO WASI, BYO JavaScriptKit SwiftRuntime, figure out BridgeJS inclusion, ...)

/**
 * Runs an ElementaryUI application.
 *
 * This function will bootstrap a new JavaScriptKit SwiftRuntime and a WASI shim, and then run the application.
 *
 * @param initializer - The initializer function that taked WebAssembly imports and returns a WebAssembly instance.
 * @returns A promise that resolves when the application is running.
 */
export async function runApplication(initializer: WasmInstanceInitializer) {
  const wasi = createDefaultWASI();
  const swiftRuntime = new SwiftRuntime();
  const bridgeJSStubs = createBridgeJSStubs();

  const instance = await initializer({
    javascript_kit: swiftRuntime.wasmImports,
    wasi_snapshot_preview1: wasi.wasiImport,
    bjs: bridgeJSStubs,
  });

  swiftRuntime.setInstance(instance);
  // TODO: deal with this typing issue later
  wasi.initialize(instance as any);

  swiftRuntime.main();
}
