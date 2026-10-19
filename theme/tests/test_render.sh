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
[ "$(sed -n '3,4p' "$tmp/s.toml")" = "$(cat "$tmp/base.toml")" ] || { echo "base must follow palette line" >&2; exit 1; }
[ "$(grep -n '^\[' "$tmp/s.toml" | tail -n1 | cut -d: -f2)" = '[palettes.rp]' ] || { echo "palette table must be last" >&2; exit 1; }
render_fzf "$tmp/f.sh"; has "$tmp/f.sh" "hl:#75608f"; has "$tmp/f.sh" "bg+:#f2e9e1"
( . "$tmp/f.sh"; case "$FZF_DEFAULT_OPTS" in *"--color=bg:-1"*) ;; *) echo "fzf opts not exported" >&2; exit 1 ;; esac )
render_lazygit "$tmp/l.yml"; has "$tmp/l.yml" "activeBorderColor: ['#75608f', bold]"
python3 -c "import sys,re
for l in open(sys.argv[1]):
    assert re.match(r'^( *[A-Za-z]+:( \[.*\])?)$', l.rstrip('\n')), l" "$tmp/l.yml" || { echo "lazygit yml malformed" >&2; exit 1; }
render_delta "$tmp/d.gitconfig"; has "$tmp/d.gitconfig" "light = true"; has "$tmp/d.gitconfig" "[delta]"
render_startpage "$tmp/s.css"; has "$tmp/s.css" "--base: #faf4ed;"; has "$tmp/s.css" "color-scheme: light"
[ "$(_rp_mix ffffff 000000 50)" = 7f7f7f ] || { echo "bad mix" >&2; exit 1; }
. "$here/../palettes/main.sh"
render_startpage "$tmp/s2.css"; has "$tmp/s2.css" "--base: #191724;"; has "$tmp/s2.css" "color-scheme: dark"
render_delta "$tmp/d2.gitconfig"; has "$tmp/d2.gitconfig" "dark = true"
echo "render ok"
