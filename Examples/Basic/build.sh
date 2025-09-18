OUTDIR=Public/lib/example

set -ex
rm -rf $OUTDIR

swift package \
  --swift-sdk "$(swiftc -print-target-info | awk -F'"' '/swiftCompilerTag/ {print $4}')_wasm-embedded" \
  --allow-writing-to-package-directory \
  js -c release --output $OUTDIR --use-cdn