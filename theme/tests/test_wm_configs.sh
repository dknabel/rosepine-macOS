#!/usr/bin/env bash
# Static checks for AeroSpace and JankyBorders configs.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
toml="$root/stow/aerospace/.config/aerospace/aerospace.toml"
brc="$root/stow/borders/.config/borders/bordersrc"
fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$toml" ] || fail "missing $toml"
[ -f "$brc" ] || fail "missing $brc"

python3 - "$toml" <<'PY' || fail "aerospace.toml checks"
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
c = tomllib.load(open(sys.argv[1], 'rb'))
def need(cond, msg):
    if not cond:
        print("FAIL: " + msg, file=sys.stderr); sys.exit(1)
g = c.get('gaps', {})
for k in ('horizontal', 'vertical'):
    need(g.get('inner', {}).get(k) == 10, 'gaps.inner.' + k)
need(g.get('outer', {}).get('left') == 10, 'gaps.outer.left')
need(g.get('outer', {}).get('bottom') == 10, 'gaps.outer.bottom')
need(g.get('outer', {}).get('right') == 10, 'gaps.outer.right')
need(g.get('outer', {}).get('top') == 50, 'gaps.outer.top')
need(c.get('start-at-login') is True, 'start-at-login')
cmd = ' '.join(c.get('exec-on-workspace-change', []))
need('aerospace_workspace_change' in cmd, 'event name')
need('FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE' in cmd, 'FOCUSED_WORKSPACE')
need(any('borders' in s for s in c.get('after-startup-command', [])), 'borders startup')
b = c.get('mode', {}).get('main', {}).get('binding', {})
keys = ['alt-' + k for k in 'hjkl'] + ['alt-shift-' + k for k in 'hjkl']
keys += ['alt-%d' % i for i in range(1, 10)] + ['alt-shift-%d' % i for i in range(1, 10)]
for k in keys:
    need(k in b, 'binding ' + k)
PY

[ -x "$brc" ] || fail "bordersrc not executable"
bash -n "$brc" || fail "bordersrc syntax"
grep -q 'RP_IRIS' "$brc" || fail "RP_IRIS"
grep -q 'RP_MUTED' "$brc" || fail "RP_MUTED"
grep -q 'style=round width=4.0' "$brc" || fail "style/width"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/empty" "$tmp/home/.local/state/rose-pine"
cat > "$tmp/bin/borders" <<'STUB'
#!/bin/sh
echo "$@" > "$STUB_OUT"
STUB
chmod +x "$tmp/bin/borders"

# colors.sh missing: must not abort, note on stderr
rm -f "$tmp/out"
HOME="$tmp/empty" PATH="$tmp/bin:$PATH" STUB_OUT="$tmp/out" bash "$brc" 2>"$tmp/err" || fail "bordersrc aborted without colors.sh"
[ -s "$tmp/err" ] || fail "expected stderr note when colors.sh missing"

# colors.sh present
cat > "$tmp/home/.local/state/rose-pine/colors.sh" <<'C'
export RP_IRIS=0xffc4a7e7
export RP_MUTED=0xff6e6a86
C
HOME="$tmp/home" PATH="$tmp/bin:$PATH" STUB_OUT="$tmp/out" bash "$brc" || fail "bordersrc failed with colors.sh"
grep -q 'active_color=0xffc4a7e7' "$tmp/out" || fail "active_color not passed"
grep -q 'inactive_color=0xff6e6a86' "$tmp/out" || fail "inactive_color not passed"
echo "test_wm_configs ok"
