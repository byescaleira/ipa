#!/bin/bash
set -euo pipefail

# Builds the server-side store engine: a small HTTP service (engine/cmd/server)
# that wraps the same ipatool package as the embedded bridge, so the iOS app can
# run login, versions and download against a backend instead of needing on-device
# JIT. Pass --docker to build the container image instead of a local binary.

project_root="$(cd "$(dirname "$0")/.." && pwd)"
engine="$project_root/engine"
ipatool="$engine/.ipatool"
ipatool_commit="1b9ff28eb467"
output="${IPA_SERVER_OUTPUT:-$project_root/engine/build/ipa-server}"

if [[ "${1:-}" == "--docker" ]]; then
  exec docker build -f "$project_root/Dockerfile" -t ipa-server "$project_root"
fi

if [[ ! -f "$ipatool/go.mod" ]]; then
  echo "Cloning ipatool at $ipatool_commit"
  git clone --quiet https://github.com/majd/ipatool.git "$ipatool"
  git -C "$ipatool" checkout --quiet "$ipatool_commit"
  rm -rf "$ipatool/.git"
fi

mkdir -p "$(dirname "$output")"
echo "Building ipa-server"
( cd "$engine" && CGO_ENABLED=1 go build -trimpath -o "$output" ./cmd/server )
echo "Built $output"
