#!/system/bin/sh
# Runs at boot when the module is removed. Without this, PackageManager keeps
# the module APK's cached package data while the ROM's APK is back on disk
# (resource ids no longer match).
rm -rf /data/system/package_cache
