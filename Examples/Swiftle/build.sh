APP_NAME=EmbeddedApp
TRIPPLE=wasm32-unknown-none-wasm

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILDSUPPORT_DIR=$(cd "$SCRIPT_DIR/../../BuildSupport" && pwd)

BUILD_DIR=$(swift build -c release --triple $TRIPPLE --show-bin-path)

set -e

swift build -c release --product $APP_NAME \
  --triple $TRIPPLE \
  --toolset "$BUILDSUPPORT_DIR/embedded-toolset.json"

"$BUILDSUPPORT_DIR/link-embedded-wasm.sh" "$BUILD_DIR" $APP_NAME

cp "$BUILD_DIR/$APP_NAME.wasm" Public/app.wasm