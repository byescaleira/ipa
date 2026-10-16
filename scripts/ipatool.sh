#!/bin/bash
set -euo pipefail

# Builds the embedded store engine: the ipatool bridge (engine/bridge.go, ours)
# plus the Unicorn CPU emulator, as IPAToolCore.xcframework and libunicorn-*.a that
# the IPA app links. The ipatool source (MIT) is cloned at a pinned commit into
# engine/.ipatool; the Unicorn source (GPLv2) is downloaded and patched for iOS.
# Everything it produces lives under IPAKit/Frameworks (git-ignored); run this once
# before building the app, or whenever engine/bridge.go changes.

project_root="$(cd "$(dirname "$0")/.." && pwd)"
engine="$project_root/engine"
ipatool="$engine/.ipatool"
ipatool_commit="1b9ff28eb467"
unicorn_version="2.1.4"
unicorn_sha="ea8863f095a0136388694e5a6063afd9bb7650e30243dd6251af59c5ce5601f4"
deployment="17.4"
frameworks="$project_root/IPAKit/Frameworks"
build="${IPA_ENGINE_BUILD:-$engine/build}"

if [[ ! -f "$ipatool/go.mod" ]]; then
  echo "Cloning ipatool at $ipatool_commit"
  git clone --quiet https://github.com/majd/ipatool.git "$ipatool"
  git -C "$ipatool" checkout --quiet "$ipatool_commit"
  rm -rf "$ipatool/.git"
fi

mkdir -p "$build" "$frameworks"

# Static Unicorn for one Apple platform slice, with ipatool's iOS W^X patch.
build_unicorn() {
  local slice="$1" sdk="$2" target="$3"
  local out="$build/unicorn-$slice"
  [[ -f "$out/out/libunicorn.a" ]] && return
  echo "Building Unicorn $unicorn_version for $slice"
  rm -rf "$out"; mkdir -p "$out"
  local tarball="$build/unicorn-$unicorn_version.tar.gz"
  if [[ ! -f "$tarball" ]]; then
    curl -fL --retry 3 \
      "https://github.com/unicorn-engine/unicorn/archive/refs/tags/$unicorn_version.tar.gz" \
      -o "$tarball"
    echo "$unicorn_sha  $tarball" | shasum -a 256 -c -
  fi
  tar -xzf "$tarball" -C "$out"
  patch -d "$out/unicorn-$unicorn_version" -p1 < "$ipatool/tools/patches/unicorn-ios.patch"
  local sdkroot
  sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  ARCHFLAGS='-arch arm64' SDKROOT="$sdkroot" cmake -S "$out/unicorn-$unicorn_version" -B "$out/out" \
    -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdkroot" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET="$deployment" \
    -DCMAKE_C_FLAGS="-target $target" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DUNICORN_ARCH=x86 -DUNICORN_BUILD_TESTS=OFF -DUNICORN_INSTALL=OFF >/dev/null
  cmake --build "$out/out" --parallel "$(sysctl -n hw.ncpu)" >/dev/null
}

# The Go bridge as a c-archive for one slice, linked against that slice's Unicorn.
build_bridge() {
  local slice="$1" sdk="$2" target="$3"
  local out="$build/bridge-$slice"
  echo "Building bridge for $slice"
  rm -rf "$out"; mkdir -p "$out"
  local sdkroot unicorn
  sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  unicorn="$build/unicorn-$slice/out/libunicorn.a"
  ( cd "$engine" && \
    SDKROOT="$sdkroot" CC="$(xcrun --sdk "$sdk" --find clang)" \
    GOOS=ios GOARCH=arm64 CGO_ENABLED=1 IPHONEOS_DEPLOYMENT_TARGET="$deployment" \
    CGO_CFLAGS="-target $target -isysroot $sdkroot" \
    CGO_LDFLAGS="-target $target -isysroot $sdkroot -Wl,-force_load,$unicorn -Wl,-export_dynamic" \
    go build -buildmode=c-archive -o "$out/libipaengine.a" . )
}

build_unicorn ios iphoneos "arm64-apple-ios$deployment"
build_unicorn sim iphonesimulator "arm64-apple-ios$deployment-simulator"
build_bridge ios iphoneos "arm64-apple-ios$deployment"
build_bridge sim iphonesimulator "arm64-apple-ios$deployment-simulator"

echo "Assembling IPAToolCore.xcframework"
headers="$build/headers"
rm -rf "$headers"; mkdir -p "$headers"
cp "$build/bridge-ios/libipaengine.h" "$headers/IPAToolCore.h"
cat > "$headers/module.modulemap" <<'MODULE'
module IPAToolCore {
    header "IPAToolCore.h"
    export *
}
MODULE
rm -rf "$frameworks/IPAToolCore.xcframework"
xcodebuild -create-xcframework \
  -library "$build/bridge-ios/libipaengine.a" -headers "$headers" \
  -library "$build/bridge-sim/libipaengine.a" -headers "$headers" \
  -output "$frameworks/IPAToolCore.xcframework" >/dev/null
cp "$build/unicorn-ios/out/libunicorn.a" "$frameworks/libunicorn-ios.a"
cp "$build/unicorn-sim/out/libunicorn.a" "$frameworks/libunicorn-sim.a"
echo "Engine ready in $frameworks"
