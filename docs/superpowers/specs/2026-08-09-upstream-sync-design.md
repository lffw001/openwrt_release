# Upstream Sync Design

## Goal

Synchronize the current repository with `ZqinKing/wrt_release` at upstream commit `4bf1cc018f8f1f08a0e1564f1cd16a38ccb004bc` while preserving the downstream firmware behavior owned by `BlackHu-art/openwrt_release`.

The upstream repository is read-only for this workflow. The completed result is pushed only to `origin`, which points to `https://github.com/BlackHu-art/openwrt_release.git`.

## Repository Safety

- Preserve the original downstream state `06803a6197f98b800a0f7f4a258321caef2edcda` as `backup/pre-upstream-sync-20260809`.
- Perform all migration work on `sync/upstream-20260809`.
- Do not rewrite published history and do not force-push.
- Connect the previously unrelated local and upstream histories with an integration merge so later upstream updates can use normal Git ancestry.
- Push only the verified integration result and backup reference to `origin`. Never push to `ZqinKing/wrt_release`.

## Source-of-Truth Rules

Upstream is the source of truth for the current project architecture:

- `build.sh` build modes and configuration-fragment assembly.
- The static module split under `wrt_core/modules/`.
- Container build support and KMOD release artifacts.
- Newly supported device definitions.
- Current GitHub Action versions and upstream workflow safety improvements.

The downstream repository is the source of truth for its custom behavior:

- Firmware and device selections.
- Package additions and removals, including the intentional removal of CUPS and EasyTier.
- Aurora theme selection and downstream default settings.
- Docker and LiBwrt device choices.
- Single-device and batch release workflows.
- Release tag naming, release retention, workflow cleanup, and cache isolation behavior.
- `CLEANUP_GUIDE.md`, `tu.png`, and other downstream-only documentation or assets.
- The custom banner file and its installation behavior.

When the two sources conflict, preserve downstream behavior while implementing it through the current upstream structure. Do not restore an obsolete upstream module merely because the downstream customization previously lived there.

## Integration Architecture

Prepare the final tree from the upstream version, then migrate downstream behavior into the corresponding current files. Record the result as an integration merge whose parents are the current downstream history and `upstream/main`. This keeps the downstream audit trail and gives future upstream synchronizations a real merge base.

Large legacy files such as the old monolithic `packages.sh` and `system.sh` are not copied over wholesale. Their still-relevant downstream behavior is placed in the focused upstream modules such as `custom_feed.sh`, `package_source_updates.sh`, `luci_fixes.sh`, `service_fixes.sh`, and `target_fixes.sh`.

## Configuration Migration

- Retain all upstream device definitions and configuration-fragment support.
- Preserve the downstream configurations for existing devices, especially `jdcloud_ipq60xx_immwrt`, `jdcloud_ipq60xx_libwrt`, `jdcloud_ax6000_immwrt`, `link_nn6000v2_immwrt`, and `x64_immwrt`.
- Move shared package selections into fragments only when they are genuinely shared; keep device-specific selections in the device `.config` files.
- Preserve explicit downstream exclusions. In particular, an upstream addition of CUPS must not undo the downstream removal.
- Preserve downstream Aurora, Docker, proxy, storage, network utility, and device LED selections where the selected package remains available.
- Use upstream `config_preview` output to confirm the final fragment order for every supported device pair.

## Banner Behavior

Keep `wrt_core/deconfig/banner` as the downstream banner source. Adapt the upstream `build.sh` so that, after the source tree exists and before compilation, it installs this file at `<BUILD_DIR>/package/base-files/files/etc/banner`.

The behavior must be:

- Create the destination directory when needed.
- Copy the custom banner when the source exists.
- Fail clearly if the configured banner exists but cannot be installed.
- Leave the OpenWrt source banner unchanged when no downstream banner file is present.
- Work for local and GitHub Actions builds without embedding an absolute path.

The existing `991_custom_settings` UCI-defaults behavior is separate from the login banner and must remain enabled through the upstream module layout.

## Workflow Migration

Use the upstream single-device workflow as the structural base so it receives fragment inputs, current actions, disk cleanup, container compatibility, new devices, and KMOD packaging.

Reapply downstream release behavior:

- Preserve manual execution unless a current downstream workflow explicitly enables another trigger.
- Preserve per-device cache isolation.
- Preserve downstream release tag naming and release-body details.
- Keep only the newest two releases per device and delete the corresponding old tags.
- Preserve completed workflow-run cleanup.

Retain the downstream batch-release capability from `release_wrt_all.yml`, but update it to call the current build interface and configuration fragments. Retain or adapt cleanup behavior without restoring workflow code that is incompatible with the upstream build structure.

## Error Handling

- Stop migration on unresolved Git conflicts or missing custom behavior.
- Treat syntax errors, invalid workflow YAML, missing device/config pairs, failed `config_preview`, or a missing banner integration as release blockers.
- If an upstream package no longer exists, record the affected downstream selection and either migrate it to its replacement or remove it only with explicit evidence that the upstream feature supersedes it.
- Do not hide failures with broad error suppression in build or verification steps.

## Verification

Before integration into `master`:

1. Confirm the working tree contains the upstream head and all downstream preservation items.
2. Run `bash -n` on every tracked shell script.
3. Parse every workflow YAML file.
4. Run `./build.sh <device> config_preview` for every matching `compilecfg/*.ini` and `deconfig/*.config` pair.
5. Verify the custom banner source, destination logic, missing-source behavior, and `991_custom_settings` installation.
6. Compare critical downstream Kconfig and workflow invariants against the pre-sync commit.
7. Inspect the final Git diff and confirm no upstream remote is a push target.

A full firmware compilation is outside this local verification because it is resource-intensive. The retained workflows remain manually triggered so pushing the synchronization does not automatically start a full build.

## Delivery

After verification, integrate the synchronization branch into local `master` without force or history rewriting. Push the backup branch and updated `master` only to `origin`. Report the upstream commit synchronized, preservation checks, test results, pushed refs, and any build verification that still needs to run in GitHub Actions.
