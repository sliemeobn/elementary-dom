#!/bin/bash
set -e

# Build the JavaScriptKit runtime (uses typescript rolldown, goshdarn const enums....)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSKITDIR="$SCRIPT_DIR/../.build/checkouts/JavaScriptKit"
VENDORDIR="$SCRIPT_DIR/../BrowserRuntime/src/vendored/javascriptkit"

cd "$JSKITDIR"
npm ci
npm i -D tslib # TODO: remove this once fixed in JavaScriptKit
npm run build

rm -rf "$VENDORDIR"/*
cp Runtime/lib/* "$VENDORDIR/"
cp LICENSE "$VENDORDIR/"

########################################################
# Build the BrowserRuntime
########################################################

cd "$SCRIPT_DIR/../BrowserRuntime"
pnpm install --frozen-lockfile
pnpm build