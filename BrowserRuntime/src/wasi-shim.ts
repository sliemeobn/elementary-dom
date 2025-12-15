import { WASI, OpenFile, File, ConsoleStdout } from "@bjorn3/browser_wasi_shim";

export function createDefaultWASI() {
  return new WASI(
    [],
    [],
    [
      new OpenFile(new File([])),
      ConsoleStdout.lineBuffered(console.log),
      ConsoleStdout.lineBuffered(console.error),
    ],
    { debug: false }
  );
}
