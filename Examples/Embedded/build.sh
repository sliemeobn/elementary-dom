JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=true swift build -c release --product EmbeddedApp \
  --triple wasm32-unknown-none-wasm \
  # -Xcc -D__Embedded
  # -Xswiftc -cxx-interoperability-mode=default \
  
  # -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor \
  # -Xswiftc -Xclang-linker -Xswiftc -nostdlib \
  # -Xlinker --export-if-defined=__main_argc_argv \
  # -Xlinker --no-entry
  # -Xswiftc -enable-experimental-feature -Xswiftc Embedded \
  # -Xswiftc -enable-experimental-feature -Xswiftc Extern \
  # -Xswiftc -wmo -Xswiftc -disable-cmo \
cp .build/release/EmbeddedApp.wasm Public/app.wasm