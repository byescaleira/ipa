#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${IPA_BUILD_ROOT:-$HOME/Library/Developer/IPABuild}"
objects="$build_root/Debug/Build/Intermediates.noindex"
catalog="$project_root/IPA/IPA/Localizable.xcstrings"

strings=()
while IFS= read -r -d '' file; do
  strings+=("$file")
done < <(find "$objects" -path '*Debug-iphonesimulator*' -name '*.stringsdata' \
  -not -path '*/IPAAudit*' -not -path '*/IPAMock*' -not -path '*/IPAPreview*' \
  -not -path '*/IPAMCP-t.build/*' -not -path '*/IPAWidgets.build/*' -not -path '*Tests*' -print0)

if [[ ${#strings[@]} -eq 0 ]]; then
  echo "No extracted strings in $objects. Run scripts/build.sh Debug first." >&2
  exit 1
fi
xcrun xcstringstool sync "$catalog" --stringsdata "${strings[@]}"
echo "Localizable: $(xcrun xcstringstool print "$catalog" | wc -l | tr -d ' ') strings"

widgets=()
while IFS= read -r -d '' file; do
  widgets+=("$file")
done < <(find "$objects" -path '*Debug-iphonesimulator*' -path '*/IPAWidgets.build/*' -name '*.stringsdata' -print0)
if [[ ${#widgets[@]} -gt 0 ]]; then
  widget_catalog="$project_root/IPA/IPAWidgets/Localizable.xcstrings"
  xcrun xcstringstool sync "$widget_catalog" --stringsdata "${widgets[@]}"
  echo "Widgets: $(xcrun xcstringstool print "$widget_catalog" | wc -l | tr -d ' ') strings"
fi
