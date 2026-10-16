#!/bin/bash
set -euo pipefail

# Builds the ipatool bridge (engine/bridge.go) as IPAToolCore.xcframework so the
# IPA app can embed the ipatool store engine. The ipatool source (MIT) is cloned
# at a pinned commit into engine/.ipatool; the bridge code in engine/ is ours.

project_root="$(cd "$(dirname "$0")/.." && pwd)"
engine="$project_root/engine"
ipatool="$engine/.ipatool"
ipatool_commit="1b9ff28eb467"
out="$project_root/IPAKit/Frameworks/IPAToolCore.xcframework"
build="${IPA_ENGINE_BUILD:-$engine/build}"

if [[ ! -f "$ipatool/go.mod" ]]; then
  echo "Cloning ipatool at $ipatool_commit"
  git clone --quiet https://github.com/majd/ipatool.git "$ipatool"
  git -C "$ipatool" checkout --quiet "$ipatool_commit"
  rm -rf "$ipatool/.git"
fi

mkdir -p "$build"

# macOS slice (host): no static Unicorn needed to build; the SAP runtime loads at
# run time on macOS with the JIT entitlement.
macos_build() {
  echo "Building macOS arm64 slice"
  ( cd "$engine" && CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 \
    go build -buildmode=c-archive -o "$build/macos-arm64/libipaengine.a" . )
}

macos_build
echo "ipatool bridge built in $build (iOS slices and xcframework: see docs/store.md)"
