OUTDIR=Public/lib/example
set -ex

swift package \
  --swift-sdk "$(swiftc -print-target-info | jq -r '.swiftCompilerTag')_wasm" \
  --allow-writing-to-package-directory \
  js -c debug --output $OUTDIR --use-cdn