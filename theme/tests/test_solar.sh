#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/../lib/render.sh"
. "$here/../lib/solar.sh"
fail() { echo "FAIL: $*" >&2; exit 1; }

near() { # near <name> <actual-minutes> <expected-minutes>
  local d=$(( $2 - $3 )); [ "$d" -lt 0 ] && d=$(( -d ))
  [ "$d" -le 4 ] || fail "$1: got $2, expected ~$3"
}
# New York: summer solstice sunrise ~05:25, sunset ~20:31 (EDT, -240).
read -r r s <<< "$(solar_times 40.7128 -74.0060 172 -240)"
near "nyc summer rise" "$r" 325; near "nyc summer set" "$s" 1231
# New York: winter solstice sunrise ~07:17, sunset ~16:32 (EST, -300).
read -r r s <<< "$(solar_times 40.7128 -74.0060 355 -300)"
near "nyc winter rise" "$r" 437; near "nyc winter set" "$s" 992
# Sydney (southern hemisphere): Dec solstice sunrise ~05:41, sunset ~20:05 (AEDT, +660).
read -r r s <<< "$(solar_times -33.8688 151.2093 355 660)"
near "sydney rise" "$r" 341; near "sydney set" "$s" 1205
# Polar night and bad input fail so callers fall back to fixed hours.
! solar_times 78 15 355 60 >/dev/null || fail "polar night should fail"
! solar_times 120 0 100 0 >/dev/null || fail "bad latitude should fail"

[ "$(solar_mode 300 325 1231)" = main ] || fail "before sunrise"
[ "$(solar_mode 325 325 1231)" = dawn ] || fail "at sunrise"
[ "$(solar_mode 1230 325 1231)" = dawn ] || fail "before sunset"
[ "$(solar_mode 1231 325 1231)" = main ] || fail "at sunset"
[ "$(solar_mode 1300 1380 120)" = main ] || fail "wrapped: day-time gap is main"
[ "$(solar_mode 1400 1380 120)" = dawn ] || fail "wrapped: after wrapped sunrise"

# auto_mode: fixed hours without a location file, solar with one.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export ROSEPINE_LOCATION_FILE="$tmp/location" ROSEPINE_DOY=172 ROSEPINE_TZ_MIN=-240
ROSEPINE_NOW_MIN=$((6*60+30)); export ROSEPINE_NOW_MIN
[ "$(auto_mode)" = main ] || fail "no location: 06:30 is main"
ROSEPINE_NOW_MIN=$((7*60+10)); [ "$(auto_mode)" = dawn ] || fail "no location: 07:10 is dawn"
echo "40.7128 -74.0060" > "$ROSEPINE_LOCATION_FILE"
ROSEPINE_NOW_MIN=$((6*60+30)); [ "$(auto_mode)" = dawn ] || fail "solar: 06:30 in June is dawn"
ROSEPINE_NOW_MIN=$((20*60+45)); [ "$(auto_mode)" = main ] || fail "solar: 20:45 in June is main"
echo "garbage" > "$ROSEPINE_LOCATION_FILE"
ROSEPINE_NOW_MIN=$((6*60+30)); [ "$(auto_mode)" = main ] || fail "bad location falls back to hours"
echo "solar ok"
