CONFIGURATION=${1:-release}

APP_NAME=App
BUILD_DIR=.build/plugins/PackageToJS/outputs/Package

set -ex
swift package --swift-sdk "${SWIFT_SDK_ID:-wasm32-unknown-wasi}" --enable-experimental-prebuilts js -c $CONFIGURATION
cp "$BUILD_DIR/$APP_NAME.wasm" Public/app.wasm