#!/usr/bin/env bash
set -euo pipefail

if [[ -z ${GITHUB_WORKSPACE:-} ]]; then
  echo 'GITHUB_WORKSPACE must be set to select the Packit rootfs.' >&2
  exit 1
fi

if [[ -z ${GITHUB_ENV:-} ]]; then
  echo 'GITHUB_ENV must be set to export the selected Packit rootfs.' >&2
  exit 1
fi

minimum_bytes=${PACKIT_MIN_ROOTFS_BYTES:-10485760}
if [[ ! $minimum_bytes =~ ^[0-9]+$ ]]; then
  echo "PACKIT_MIN_ROOTFS_BYTES must be a non-negative integer: $minimum_bytes" >&2
  exit 1
fi

firmware_dir="$GITHUB_WORKSPACE/firmware"
shopt -s nullglob
candidates=("$firmware_dir"/*-armsr-armv8-generic-rootfs.tar.gz)
shopt -u nullglob

if (( ${#candidates[@]} != 1 )); then
  echo "Expected exactly one Packit rootfs candidate, found ${#candidates[@]}." >&2
  if (( ${#candidates[@]} > 0 )); then
    printf 'Candidates:\n' >&2
    printf '  %s\n' "${candidates[@]}" >&2
  fi
  exit 1
fi

rootfs=${candidates[0]}
rootfs_size=$(stat -c '%s' "$rootfs")
if (( rootfs_size < minimum_bytes )); then
  echo "Packit rootfs is smaller than the required $minimum_bytes bytes: $rootfs_size ($rootfs)" >&2
  exit 1
fi

if ! tar -tzf "$rootfs" >/dev/null; then
  echo "Packit rootfs is not a readable gzip tar archive: $rootfs" >&2
  exit 1
fi

printf 'OPENWRT_ARMVIRT=firmware/%s\n' "$(basename "$rootfs")" >> "$GITHUB_ENV"
