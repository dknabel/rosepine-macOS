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

# Starship base: missing file warns on stderr but still renders.
err="$(ROSEPINE_STARSHIP_BASE=/nonexistent/base.toml "$sw" dawn 2>&1 >/dev/null)"
case "$err" in *"starship base not found"*) ;; *) echo "expected warning, got: $err" >&2; exit 1 ;; esac
[ "$(head -n1 "$state/starship.toml")" = 'palette = "rp"' ]
# Present file: appended, no warning.
printf '[character]\nsuccess_symbol = "x"\n' > "$state/base.toml"
err="$(ROSEPINE_STARSHIP_BASE="$state/base.toml" "$sw" dawn 2>&1 >/dev/null)"
[ -z "$err" ] || { echo "unexpected stderr: $err" >&2; exit 1; }
grep -q 'success_symbol = "x"' "$state/starship.toml"
echo "starship base ok"

# Real base is appended to the rendered starship config.
"$sw" dawn
grep -q '^\[directory\]' "$state/starship.toml" || { echo "base.toml not appended" >&2; exit 1; }
echo "base ok"
