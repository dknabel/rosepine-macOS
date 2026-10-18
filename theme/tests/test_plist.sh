#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
p="$root/launchd/com.user.rosepine.plist"
fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "$p" ] || fail "missing $p"
plutil -lint "$p" >/dev/null || fail "plutil -lint"
grep -q RunAtLoad "$p" || fail "RunAtLoad"
[ "$(plutil -extract RunAtLoad raw "$p")" = "true" ] || fail "RunAtLoad not true"
[ "$(plutil -extract StartCalendarInterval.0.Hour raw "$p")" = "7" ] || fail "hour 7"
[ "$(plutil -extract StartCalendarInterval.1.Hour raw "$p")" = "19" ] || fail "hour 19"
plutil -extract EnvironmentVariables.PATH raw "$p" >/dev/null || fail "PATH env"
grep -q __HOME__ "$p" || fail "__HOME__ placeholder"
[ "$(plutil -extract Label raw "$p")" = "com.user.rosepine" ] || fail "Label"
echo "ok test_plist"
