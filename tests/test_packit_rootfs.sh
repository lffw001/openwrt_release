#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
selector="$repo_root/wrt_core/ci/select_packit_rootfs.sh"
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

assert_no_rootfs_env() {
  local env_file=$1
  ! grep -q '^OPENWRT_ARMVIRT=' "$env_file"
}

expect_failure() {
  local case_name=$1
  local workspace=$2
  local env_file=$3
  local output_file=$4
  shift 4

  if GITHUB_WORKSPACE="$workspace" GITHUB_ENV="$env_file" "$@" bash "$selector" >"$output_file" 2>&1; then
    echo "$case_name unexpectedly succeeded" >&2
    return 1
  fi
  assert_no_rootfs_env "$env_file"
}

make_workspace() {
  local name=$1
  local workspace="$test_root/$name"
  mkdir -p "$workspace/firmware"
  : > "$workspace/github_env"
  printf '%s\n' "$workspace"
}

workspace=$(make_workspace zero-candidates)
expect_failure "zero candidates" "$workspace" "$workspace/github_env" "$workspace/output" env
grep -q 'Expected exactly one Packit rootfs candidate, found 0' "$workspace/output"

workspace=$(make_workspace two-candidates)
touch "$workspace/firmware/one-armsr-armv8-generic-rootfs.tar.gz"
touch "$workspace/firmware/two-armsr-armv8-generic-rootfs.tar.gz"
expect_failure "two candidates" "$workspace" "$workspace/github_env" "$workspace/output" env
grep -q 'Expected exactly one Packit rootfs candidate, found 2' "$workspace/output"
grep -q 'one-armsr-armv8-generic-rootfs.tar.gz' "$workspace/output"
grep -q 'two-armsr-armv8-generic-rootfs.tar.gz' "$workspace/output"

workspace=$(make_workspace small-candidate)
small_rootfs="$workspace/firmware/small-armsr-armv8-generic-rootfs.tar.gz"
printf 'not-a-tar\n' > "$small_rootfs"
expect_failure "small candidate" "$workspace" "$workspace/github_env" "$workspace/output" env
grep -q 'smaller than the required' "$workspace/output"

workspace=$(make_workspace invalid-tar)
invalid_rootfs="$workspace/firmware/invalid-armsr-armv8-generic-rootfs.tar.gz"
dd if=/dev/urandom of="$invalid_rootfs" bs=1M count=11 status=none
expect_failure "invalid tar" "$workspace" "$workspace/github_env" "$workspace/output" env
grep -q 'not a readable gzip tar archive' "$workspace/output"

workspace=$(make_workspace valid-tar)
payload="$workspace/payload.bin"
valid_rootfs="$workspace/firmware/valid-armsr-armv8-generic-rootfs.tar.gz"
dd if=/dev/urandom of="$payload" bs=1M count=11 status=none
tar -C "$workspace" -czf "$valid_rootfs" payload.bin
GITHUB_WORKSPACE="$workspace" GITHUB_ENV="$workspace/github_env" bash "$selector"
grep -Fx 'OPENWRT_ARMVIRT=firmware/valid-armsr-armv8-generic-rootfs.tar.gz' "$workspace/github_env"
test "$(wc -l < "$workspace/github_env")" -eq 1

echo 'Packit rootfs selection behavior: PASS'
