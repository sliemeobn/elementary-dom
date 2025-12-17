//#region src/index.d.ts
type WasmInstanceInitializer = (importsObject?: WebAssembly.Imports) => Promise<WebAssembly.Instance>;
/**
 * Runs an ElementaryUI application.
 *
 * This function will bootstrap a new JavaScriptKit SwiftRuntime and a WASI shim, and then run the application.
 *
 * @param initializer - The initializer function that taked WebAssembly imports and returns a WebAssembly instance.
 * @returns A promise that resolves when the application is running.
 */
declare function runApplication(initializer: WasmInstanceInitializer): Promise<void>;
//#endregion
export { runApplication };