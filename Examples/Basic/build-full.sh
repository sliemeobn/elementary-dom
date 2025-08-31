OUTDIR=Public/lib/example

set -ex
rm -rf $OUTDIR

swift package \
  --swift-sdk "$(swiftc -print-target-info | jq -r '.swiftCompilerTag')_wasm" \
  --allow-writing-to-package-directory \
  js -c release --output $OUTDIR --use-cdn