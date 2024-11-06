async function main() {
  // Fetch our Wasm File
  const response = await fetch(`app.wasm`);
  // Create a new WASI system instance
  // const wasi = new WASI(
  //   /* args */ ["main.wasm"],
  //   /* env */ [],
  //   /* fd */ [
  //     new OpenFile(new File([])), // stdin
  //     ConsoleStdout.lineBuffered((stdout) => {
  //       console.log(stdout);
  //     }),
  //     ConsoleStdout.lineBuffered((stderr) => {
  //       console.error(stderr);
  //     }),
  //     new PreopenDirectory("/", new Map()),
  //   ]
  // );
  const { SwiftRuntime } = await import(`./javascript-kit/index.mjs`);
  // Create a new Swift Runtime instance to interact with JS and Swift
  const swift = new SwiftRuntime();
  // Instantiate the WebAssembly file
  const { instance } = await WebAssembly.instantiateStreaming(response, {
    //wasi_snapshot_preview1: wasi.wasiImport,
    javascript_kit: swift.wasmImports,
  });
  // Set the WebAssembly instance to the Swift Runtime
  swift.setInstance(instance);
  // Start the WebAssembly WASI reactor instance
  // wasi.initialize(instance);
  // Start Swift main function
  swift.main();
}

main();
