OUTDIR=Public/lib/swiftle
set -ex

swift package \
  --swift-sdk "$(swiftc -print-target-info | jq -r '.swiftCompilerTag')_wasm" \
  --enable-experimental-prebuilts \
  --allow-writing-to-package-directory \
  js -c debug --output $OUTDIR --use-cdn