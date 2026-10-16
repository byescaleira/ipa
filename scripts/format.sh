#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
formatter="$(xcrun --find swift-format)"

case "${1:-}" in
  "")
    arguments=(format --in-place)
    ;;
  --check)
    arguments=(lint --strict)
    ;;
  *)
    echo "Usage: scripts/format.sh [--check]" >&2
    exit 2
    ;;
esac

paths=()
for path in \
  "$project_root/IPA/IPA" \
  "$project_root/IPA/Shared" \
  "$project_root/IPA/IPAWidgets" \
  "$project_root/IPAKit/Sources" \
  "$project_root/IPAKit/Tests" \
  "$project_root/IPAKit/Package.swift"; do
  [[ -e "$path" ]] && paths+=("$path")
done

"$formatter" "${arguments[@]}" \
  --configuration "$project_root/.swift-format" --recursive --parallel "${paths[@]}"
