#!/bin/bash
# Host-side check of module/sepolicy.rule against a built AOSP policy.
#
#   scripts/check-sepolicy.sh <sepolicy_neverallows.checkpolicy.conf> [checkpolicy]
#
# The conf is the m4-expanded platform policy from a tree build
# (out/soong/.intermediates/system/sepolicy/sepolicy_neverallows.checkpolicy.conf/
#  android_common/). The magiskpolicy "allow s t class perms" lines are
# converted to checkpolicy syntax and appended; checkpolicy then fails on
# unknown types/classes/perms and on neverallow violations.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="${1:?usage: $0 <policy.conf> [checkpolicy]}"
CHECKPOLICY="${2:-checkpolicy}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Rules must precede the trailing context section (users/contexts section).
START="$(grep -n -m1 -E '^#line 1 ".*private/users"' "$CONF" | cut -d: -f1)"
head -n $((START - 1)) "$CONF" > "$TMP/policy.conf"
grep -vE '^\s*(#|$)' "$ROOT/module/sepolicy.rule" | while read -r line; do
    # allow <src> <tgt> <class> <perm|{ perms }>  ->  allow src tgt:class perms;
    echo "$line" | sed -E 's/^allow ([^ ]+) ([^ ]+) ([^ ]+) (.*)$/allow \1 \2:\3 \4;/'
done >> "$TMP/policy.conf"
tail -n +"$START" "$CONF" >> "$TMP/policy.conf"

"$CHECKPOLICY" -M -c 30 -o "$TMP/policy.bin" "$TMP/policy.conf" >/dev/null
echo "OK: sepolicy.rule compiles and passes neverallow checks"
