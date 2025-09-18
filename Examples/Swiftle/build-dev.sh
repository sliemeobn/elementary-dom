OUTDIR=Public/lib/swiftle
set -ex

swift package \
  --swift-sdk "$(swiftc -print-target-info | awk -F'"' '/swiftCompilerTag/ {print $4}')_wasm" \
  --allow-writing-to-package-directory \
  js -c debug --output $OUTDIR --use-cdn --debug-info-format dwarf