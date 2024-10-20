JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=true EXPERIMENTAL_EMBEDDED_WASM=true swift build -c release --product EmbeddedApp \
  --triple wasm32-unknown-none-wasm  \
  -Xswiftc -enable-experimental-feature -Xswiftc Embedded \
  -Xswiftc -enable-experimental-feature -Xswiftc Extern \
  -Xswiftc -wmo -Xswiftc -disable-cmo \
  -Xswiftc -cxx-interoperability-mode=default \
  -Xcc -D__Embedded -Xcc -fdeclspec \
  -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor \
  -Xswiftc -Xclang-linker -Xswiftc -nostdlib \
  -Xlinker --export-if-defined=__main_argc_argv \
  -Xlinker --no-entry

cp .build/release/EmbeddedApp.wasm Public/app.wasm