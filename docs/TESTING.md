# Testing the module without a physical device

Verified on 2026-10-15 with an Android 15 (API 35) x86_64 emulator image built
from a self-built LineageOS tree (`ro.build.tags=test-keys`), Magisk v30.7.

## Static (CI + local)
- CI (`.github/workflows/build.yml`): shell lint, build, zip layout, installer
  markers, APK cert = AOSP test platform key, privapp XML well-formed.
- `scripts/check-sepolicy.sh`: `sepolicy.rule` compiles into the tree's policy and
  passes neverallow checks.

## Emulator with Magisk
1. Boot the system image once (unrooted).
2. Root it with [rootAVD](https://github.com/newbit1/rootAVD). Its bundled
   Magisk 25.2 **kernel-panics** on this Android 15 image, and it does not know
   Magisk >= 28's file layout, so apply `docs/rootAVD-magisk30.patch`
   (relaxes the busybox check, uses `magisk` + `init-ld`), put the official
   `Magisk-v30.7.apk` in as `Magisk.zip`, and run it with `ANDROID_SERIAL` set
   to the emulator so a connected phone can never be touched.
3. Cold-boot with the patched `ramdisk.img`. Magisk has no app set-up on an
   emulator, so push `util_functions.sh`, `busybox` and `magiskboot` from the
   APK into `/data/adb/magisk/` before running
   `/debug_ramdisk/magisk --install-module kamen.zip`.
4. Reboot and check `pm list packages --show-versioncode`.

To tell the module's APK from one baked into the image, build the module with
a higher `VERSION_CODE` (`VERSION_CODE=100 scripts/build-module.sh ...`).

## Results
| Check | Result |
|---|---|
| Installer checks (API, test-keys, APK present) | pass |
| Overlay serves module APK at `/system_ext/priv-app/...` (md5 matches) | pass |
| App runs as uid 1000 / PRIVILEGED / SYSTEM_EXT from the module APK | pass |
| `INJECT_EVENTS`, `READ_FRAME_BUFFER`, `CAPTURE_VIDEO_OUTPUT` granted | pass |
| Service starts, `ScreenCaptureService` + `InputInjectionService` init, no `avc: denied` | pass |
| Remove module: ROM APK returns, version reverts, no resource errors | pass |
| Real frame capture / input injection driven by a task (needs the mock LLM suite) | **not run** |
| `sepolicy.rule` effect A/B on a running device | **not run** (only compile-checked) |

## Bug found and fixed
PackageManager's `/data/system/package_cache` kept serving the previous APK's
data after the overlay changed: after flashing, `versionCode` stayed at the baked
35 until the cache was cleared; after disabling, it stayed at 99 and logged
`Failure retrieving text ... in package` (resource ids no longer matched).
`customize.sh` and `uninstall.sh` now clear the cache. Merely *disabling* the
module (not removing it) still leaves a stale cache; remove it instead, or clear
`/data/system/package_cache` and reboot.
