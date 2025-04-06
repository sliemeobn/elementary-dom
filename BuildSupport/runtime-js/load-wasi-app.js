export async function loadWasiApp(wasmFileName, runtimePath) {
  const [response, jsk, wasi_shim] = await Promise.all([
    fetch(wasmFileName),
    import(runtimePath || "./javascriptkit.js"),
    import("https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.1/+esm"),
  ]);

  let wasi = new wasi_shim.WASI(
    [wasmFileName],
    [],
    [
      new wasi_shim.OpenFile(new wasi_shim.File([])), // stdin
      wasi_shim.ConsoleStdout.lineBuffered((msg) => console.log(msg)),
      wasi_shim.ConsoleStdout.lineBuffered((msg) => console.error(msg)),
      new wasi_shim.PreopenDirectory("/", new Map()),
    ]
  );

  const swift = new jsk.SwiftRuntime();
  const { instance } = await WebAssembly.instantiateStreaming(response, {
    javascript_kit: swift.wasmImports,
    wasi_snapshot_preview1: wasi.wasiImport,
  });
  wasi.initialize(instance);
  swift.setInstance(instance);
  swift.main();
}
