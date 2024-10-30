JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=true swift build -c release --product EmbeddedApp \
  --triple wasm32-unknown-none-wasm \

cp .build/release/EmbeddedApp.wasm Public/app.wasm