#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/../lib/render.sh"
check() { [ "$(mode_for_hour "$1")" = "$2" ] || { echo "hour $1: expected $2" >&2; exit 1; }; }
check 6 main; check 7 dawn; check 18 dawn; check 19 main; check 0 main; check 23 main
echo "mode ok"
