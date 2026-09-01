#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/wrt_core/modules/banner.sh"

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

source_banner="$test_root/custom-banner"
build_root="$test_root/build"
target_banner="$build_root/package/base-files/files/etc/banner"
printf 'Frankie downstream banner\n' > "$source_banner"

install_custom_banner "$source_banner" "$build_root"
cmp "$source_banner" "$target_banner"

printf 'OpenWrt default banner\n' > "$target_banner"
install_custom_banner "$test_root/missing-banner" "$build_root"
grep -Fx 'OpenWrt default banner' "$target_banner"

echo "banner behavior: PASS"
