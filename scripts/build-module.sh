#!/bin/bash
# Build the Magisk module zip.
#
#   scripts/build-module.sh [app-repo]
#
# app-repo: checkout of AgentVis-OS/aiphone_assistant. Defaults to $APP_REPO,
# else ../aiphone_assistant, else a pinned clone in .cache/ (APP_REF, default main).
# The app repo stays the single source of truth for the APK and the privapp
# allowlist; nothing from it is committed here.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Magisk's module installer stub (becomes META-INF/.../update-binary), pinned.
INSTALLER_URL="https://raw.githubusercontent.com/topjohnwu/Magisk/v28.1/scripts/module_installer.sh"
INSTALLER_SHA256="bcf4b1d9913f3af17755569c853e0b5a75b8005f6a18eb3f86dadcc0e968c29d"
APP_URL="${APP_URL:-https://github.com/AgentVis-OS/aiphone_assistant}"
APP_REF="${APP_REF:-main}"
APP="${1:-${APP_REPO:-}}"

if [ -z "$APP" ]; then
    if [ -d "$ROOT/../aiphone_assistant/.git" ]; then
        APP="$ROOT/../aiphone_assistant"
    else
        APP="$ROOT/.cache/aiphone_assistant"
        [ -d "$APP/.git" ] || git clone "$APP_URL" "$APP"
        git -C "$APP" fetch -q origin && git -C "$APP" checkout -q "$APP_REF"
    fi
fi
APP="$(readlink -f "$APP")"

"$APP/tools/build-apk.sh"

INSTALLER="$ROOT/.cache/module_installer.sh"
if ! echo "$INSTALLER_SHA256  $INSTALLER" | sha256sum -c --quiet >/dev/null 2>&1; then
    mkdir -p "$ROOT/.cache"; curl -fsSL -o "$INSTALLER" "$INSTALLER_URL"
    echo "$INSTALLER_SHA256  $INSTALLER" | sha256sum -c --quiet \
        || { echo "sha256 mismatch: module_installer.sh" >&2; exit 1; }
fi

STAGE="$ROOT/build/module"
rm -rf "$STAGE"; mkdir -p "$ROOT/dist" "$ROOT/build"
cp -r "$ROOT/module" "$STAGE"
find "$STAGE" -name .gitkeep -delete
META="$STAGE/META-INF/com/google/android"; mkdir -p "$META"
cp "$INSTALLER" "$META/update-binary"; echo "#MAGISK" > "$META/updater-script"
cp "$APP/out/AIPhoneAssistant.apk" "$STAGE/system/system_ext/priv-app/AIPhoneAssistant/"
cp "$APP/privapp-permissions-aiphoneassistant.xml" "$STAGE/system/system_ext/etc/permissions/"

VER="$(sed -n 's/^version=//p' "$STAGE/module.prop")"
OUT="$ROOT/dist/kamen-aiphone-$VER.zip"
rm -f "$OUT"; (cd "$STAGE" && zip -qr "$OUT" .)
echo "Built $OUT (app $(git -C "$APP" rev-parse --short HEAD))"
