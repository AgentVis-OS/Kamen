# Magisk installer hook (sourced by the Magisk module installer).
SKIPUNZIP=0

ui_print "- Kamen: AI Phone Assistant"

if [ "$API" -lt 35 ]; then
  abort "! Android 15 (API 35) or newer required, found API $API"
fi

# The bundled APK is signed with the public AOSP test platform key. On any
# other key the system-UID / signature permissions never grant.
TAGS="$(getprop ro.build.tags)"
case "$TAGS" in
  *test-keys*) ;;
  *) abort "! ROM is signed with '$TAGS', not test-keys. This build cannot work here." ;;
esac

[ -f "$MODPATH/system/system_ext/priv-app/AIPhoneAssistant/AIPhoneAssistant.apk" ] \
  || abort "! APK missing from module zip (build it with scripts/build-module.sh)"

# PackageManager caches parsed packages and keeps serving the old APK's data
# after the overlay changes, so drop the cache; it is rebuilt on next boot.
ui_print "- Clearing PackageManager cache so the new APK is picked up on next boot"
rm -rf /data/system/package_cache
set_perm_recursive "$MODPATH/system/system_ext" 0 0 0755 0644
ui_print "- SELinux rules come from sepolicy.rule; check 'dmesg | grep avc' on denials"
