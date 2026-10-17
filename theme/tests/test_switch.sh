#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sw="$here/../../stow/theme/.local/bin/rosepine-switch"
state="$(mktemp -d)"; trap 'rm -rf "$state"' EXIT
export ROSEPINE_DRY_RUN=1 ROSEPINE_STATE_DIR="$state"
"$sw" dawn
for f in colors.sh tmux.conf starship.toml mode; do [ -s "$state/$f" ] || { echo "missing $f" >&2; exit 1; }; done
grep -q dawn "$state/mode"
cp "$state/colors.sh" "$state/colors.dawn"
"$sw" main
grep -q main "$state/mode"
! cmp -s "$state/colors.sh" "$state/colors.dawn" || { echo "colors.sh did not change" >&2; exit 1; }
grep -q 'export RP_IRIS=0xffc4a7e7' "$state/colors.sh"
echo "switch ok"
