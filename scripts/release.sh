#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_root="${IPA_BUILD_ROOT:-$HOME/Library/Developer/IPABuild}/Release"
source_root="${IPA_SOURCE_ROOT:-$project_root/../apps}"
repository="byescaleira/ipa"
publish=false
notes=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --publish) publish=true ;;
    --notes) notes="$2"; shift ;;
    *) echo "usage: $0 [--publish] [--notes <text>]" >&2; exit 2 ;;
  esac
  shift
done

settings() {
  xcodebuild -workspace "$project_root/IPA.xcworkspace" -scheme Production -configuration Release \
    -showBuildSettings -destination 'generic/platform=iOS' 2>/dev/null | awk -F' = ' -v key="$1" '$1 ~ " "key"$" {print $2; exit}'
}
version="$(settings MARKETING_VERSION)"
build="$(settings CURRENT_PROJECT_VERSION)"
minimum="$(settings IPHONEOS_DEPLOYMENT_TARGET)"
tag="v$version-$build"
package="$build_root/IPA-$version-$build.ipa"

rm -rf "$build_root/IPA.xcarchive" "$build_root/Payload" "$package"
xcodebuild -workspace "$project_root/IPA.xcworkspace" -scheme Production -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$build_root/IPA.xcarchive" \
  -derivedDataPath "$build_root/Derived" -skipPackageUpdates \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= COMPILER_INDEX_STORE_ENABLE=NO archive
mkdir -p "$build_root/Payload"
cp -R "$build_root/IPA.xcarchive/Products/Applications/IPA.app" "$build_root/Payload/"
(cd "$build_root" && zip -qry "$package" Payload)
rm -rf "$build_root/Payload"
size="$(stat -f%z "$package")"
echo "Built $package ($size bytes), version $version ($build), iOS $minimum"

if [[ "$publish" != true ]]; then
  echo "Dry run: pass --publish to create the $tag release and update the source."
  exit 0
fi

gh release create "$tag" "$package" --repo "$repository" --title "IPA $version ($build)" \
  --notes "${notes:-IPA $version ($build).}" --target "$(git -C "$project_root" rev-parse HEAD)"
url="https://github.com/$repository/releases/download/$tag/$(basename "$package")"
python3 "$source_root/scripts/add-version.py" com.byescaleira.ipa "$version" "$build" "$url" "$size" \
  --min-os "$minimum" --notes "$notes"
echo "Source updated in $source_root; commit and push it to publish."
