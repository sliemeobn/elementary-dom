APP_NAME=EmbeddedApp

BUILD_DIR=.build/plugins/PackageToJS/outputs/Package/

set -e

swift package --swift-sdk DEVELOPMENT-SNAPSHOT-2025-03-25-a-wasm32-unknown-wasi js --use-cdn -c release

cp "$BUILD_DIR/$APP_NAME.wasm" Public/app.wasm