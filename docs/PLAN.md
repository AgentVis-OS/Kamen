# Kamen plan

Goal: `scripts/build-module.sh` produces a zip; flashing it in Magisk on a
test-keys LineageOS 22.2+ device gives a working, privileged AIPhoneAssistant
with no ROM rebuild. Kamen stays separate from WD40 and does not replace its
Magisk skeleton. It is not tested on the maintainer's physical device;
verification is static plus emulator.

## Design

- App repo is the source of truth: Kamen builds the APK with its
  `tools/build-apk.sh` and copies the privapp allowlist from it. No app code or
  duplicated XML is committed here.
- Priv-app placed at `system/system_ext/priv-app/AIPhoneAssistant/` (Magisk
  overlays it), allowlist at `system/system_ext/etc/permissions/`.
- SELinux via `sepolicy.rule` (native Magisk mechanism), not `post-fs-data.sh`.
  WD40's skeleton calls `binder_call` through `magiskpolicy`, which does not
  support m4 macros; Kamen expands it. Worth back-porting a fix to WD40.

## Milestones

1. **M0 scaffold** - this commit: layout, build script, rules, installer checks.
2. **M1 verification (no physical device)** - static part done: zip layout, APK
   cert, and `scripts/check-sepolicy.sh` pass. Remaining: emulator run. Original scope: - static checks (zip layout,
   `apksigner verify`, `magiskpolicy` load of `sepolicy.rule` against a built
   policy) and the `~/aiphone-emu` emulator with Magisk: package is a priv-app,
   permissions granted (`dumpsys package com.android.aiphoneassistant`), no
   `avc: denied`.
3. **M2 data-app conflict** - the device currently has the app adb-installed in
   `/data`. Verify the module copy wins (or uninstall first); document the
   upgrade path and add an `uninstall.sh` if state needs cleanup.
4. **M3 robustness** - boot-loop safety (privapp enforce mode), module
   updates via `updateJson`, versionCode derived from the app repo commit/tag.
5. **M4 CI/release** - GitHub Actions mirroring the app repo's workflow:
   build zip on tag, attach to release with sha256.

## Open questions

- Pin `APP_REF` to a tag/commit for reproducible zips, or track `main`?
- Does Magisk's overlay of `system_ext` work on this device's partition layout
  (system_ext as a separate mount), or is a `REPLACE`/`post-fs-data` mount needed?
- Support other keys later (e.g. user-supplied platform key at build time)?
  Official release-keys ROMs would need the ROM's private key, so likely out of scope.
