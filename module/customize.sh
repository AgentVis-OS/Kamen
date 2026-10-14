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

# Drop any /data update of the package so the systemless copy is the one used.
ui_print "- If the app was previously adb-installed, it is replaced on next boot"
set_perm_recursive "$MODPATH/system/system_ext" 0 0 0755 0644
ui_print "- SELinux rules come from sepolicy.rule; check 'dmesg | grep avc' on denials"
