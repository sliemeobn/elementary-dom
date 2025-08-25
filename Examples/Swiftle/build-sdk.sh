CONFIGURATION=${1:-release}

APP_NAME=EmbeddedApp
BUILD_DIR=.build/plugins/PackageToJS/outputs/Package

if [ -z "$SWIFT_SDK_ID" ]; then
  SWIFT_SDK_ID="$(swiftc -print-target-info | jq -r '.swiftCompilerTag')_wasm-embedded"
fi

set -ex
swift package --swift-sdk $SWIFT_SDK_ID --enable-experimental-prebuilts js -c $CONFIGURATION
cp "$BUILD_DIR/$APP_NAME.wasm" Public/app.wasm