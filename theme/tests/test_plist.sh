#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p="$root/launchd/com.user.rosepine.plist"
fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "$p" ] || fail "missing $p"
plutil -lint "$p" >/dev/null || fail "plutil -lint"
grep -q RunAtLoad "$p" || fail "RunAtLoad"
[ "$(plutil -extract RunAtLoad raw "$p")" = "true" ] || fail "RunAtLoad not true"
[ "$(plutil -extract StartInterval raw "$p")" = "900" ] || fail "StartInterval 900"
grep -q "rosepine-switch\" tick" "$p" || fail "plist runs tick"
plutil -extract EnvironmentVariables.PATH raw "$p" >/dev/null || fail "PATH env"
grep -q __HOME__ "$p" || fail "__HOME__ placeholder"
[ "$(plutil -extract Label raw "$p")" = "com.user.rosepine" ] || fail "Label"
echo "ok test_plist"
