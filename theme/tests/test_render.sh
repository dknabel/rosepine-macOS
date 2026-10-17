#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$here/../lib/render.sh"
. "$here/../palettes/dawn.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
has() { grep -qF -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
render_colors_sh "$tmp/c.sh"; has "$tmp/c.sh" "export RP_IRIS=0xff907aa9"
render_tmux "$tmp/t.conf"; has "$tmp/t.conf" "#faf4ed"
printf '[character]\nsuccess_symbol = "x"\n' > "$tmp/base.toml"
render_starship "$tmp/s.toml" "$tmp/base.toml"
[ "$(head -n1 "$tmp/s.toml")" = 'palette = "rp"' ] || { echo "bad first line" >&2; exit 1; }
has "$tmp/s.toml" 'base = "#faf4ed"'
has "$tmp/s.toml" '[palettes.rp]'
[ "$(tail -n2 "$tmp/s.toml")" = "$(cat "$tmp/base.toml")" ] || { echo "base not at end" >&2; exit 1; }
echo "render ok"
