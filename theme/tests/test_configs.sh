#!/usr/bin/env bash
# Static checks for ghostty, tmux, zsh and starship configs.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
base="$root/stow/starship/.config/starship/base.toml"
ghostty="$root/stow/ghostty/.config/ghostty/config"
tmuxc="$root/stow/tmux/.config/tmux/tmux.conf"
zshf="$root/stow/zsh/.zshrc.d/rosepine.zsh"
fail() { echo "FAIL: $*" >&2; exit 1; }

for f in "$base" "$ghostty" "$tmuxc" "$zshf"; do [ -f "$f" ] || fail "missing $f"; done

python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
tomllib.load(open(sys.argv[1],'rb'))" "$base" || fail "base.toml invalid TOML (python3 needs tomllib or tomli)"

if grep -Eq '#[0-9a-fA-F]{6}' "$base"; then fail "hex literal in base.toml"; fi

names="base surface overlay muted subtle text love gold rose pine foam iris on_accent prompt_ok"
used="$( { grep -oE '(fg|bg):[a-z_]+' "$base" | cut -d: -f2 || true; grep -oE '(style|color) *= *"[a-z_]+"' "$base" | sed -E 's/.*"([a-z_]+)"/\1/' || true; } | sort -u)"
for u in $used; do
  case " $names " in *" $u "*) ;; *) fail "unknown palette color '$u' in base.toml" ;; esac
done

grep -qxF 'theme = light:Rose Pine Dawn Legible,dark:Rose Pine' "$ghostty" || fail "ghostty theme line"

grep -qF 'STARSHIP_CONFIG="$HOME/.local/state/rose-pine/starship.toml"' "$zshf" || fail "STARSHIP_CONFIG not set"
if command -v zsh >/dev/null 2>&1; then zsh -n "$zshf" || fail "zsh -n"; fi
echo "test_configs ok"
