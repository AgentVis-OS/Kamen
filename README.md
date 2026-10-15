# Kamen

Magisk module that installs [AIPhoneAssistant](https://github.com/AgentVis-OS/aiphone_assistant)
as a systemless `system_ext` priv-app on a rooted device, with the SELinux
rules it needs. A separate project from [WD40](https://github.com/Inokinoki/WD40) (which bakes
the same changes into a ROM build and keeps its own Magisk skeleton, untouched);
Kamen needs no ROM build.

Status: scaffold. See [docs/PLAN.md](docs/PLAN.md).

## Build

```bash
scripts/build-module.sh [path/to/aiphone_assistant]   # -> dist/kamen-aiphone-<ver>.zip
```

Needs JDK 17+ and Android build-tools >= 35 (see the app repo's `tools/build-apk.sh`).
Flash the zip in Magisk (or recovery), reboot. If the app was adb-installed
before, `adb uninstall com.android.aiphoneassistant` first, otherwise a newer
`/data` copy shadows the module's.

## Constraint

The APK is signed with the public AOSP **test** platform key, so the target
ROM must be `ro.build.tags=test-keys` (self-built LineageOS). Official
release-keys ROMs are refused by the installer.

## Layout

- `module/` - Magisk module template (`module.prop`, `customize.sh`, `sepolicy.rule`)
- `scripts/build-module.sh` - builds the APK via the app repo, stages and zips the module
- `scripts/check-sepolicy.sh` - compiles `sepolicy.rule` into a tree's policy conf (catches unknown types and neverallow hits)
- `.github/workflows/build.yml` - CI: lint, build zip, test layout/signature, release on `v*` tags
- `docs/TESTING.md` - emulator test procedure, results and known caveats
- `docs/PLAN.md` - roadmap and open questions
