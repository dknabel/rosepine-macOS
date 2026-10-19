#!/usr/bin/env bash
# WCAG contrast lint: text colors must stay readable on their backgrounds in both modes.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$here/../.."
theme="$root/stow/ghostty/.config/ghostty/themes/Rose Pine Dawn Legible"

python3 - "$root/theme/palettes" "$theme" <<'P'
import re, sys

pal_dir, ghostty_theme = sys.argv[1:3]

def load(path):
    return {m.group(1): m.group(2).lower()
            for m in re.finditer(r'^RP_([A-Z_]+)=([0-9a-fA-F]{6})$', open(path).read(), re.M)}

def lum(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

def ratio(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)

# (foreground, background, minimum ratio)
PAIRS = [
    ("TEXT", "BASE", 4.5), ("TEXT", "SURFACE", 4.5), ("TEXT", "OVERLAY", 4.5),
    ("DIM_TEXT", "BASE", 4.5), ("ACCENT_TEXT", "BASE", 4.5),
    ("HILITE_TEXT", "BASE", 4.5), ("PROMPT_OK", "BASE", 4.5),
    ("MARK_TEXT", "OVERLAY", 4.5),
    ("ON_ACCENT", "IRIS", 4.5), ("ON_ACCENT", "FOAM", 4.5), ("ON_ACCENT", "LOVE", 4.0),
]

bad = []
for mode in ("main", "dawn"):
    p = load(f"{pal_dir}/{mode}.sh")
    for fg, bg, need in PAIRS:
        r = ratio(p[fg], p[bg])
        if r < need:
            bad.append(f"{mode}: {fg} on {bg} = {r:.2f} (< {need})")

# The light terminal theme's ANSI palette must be legible on its own background.
t = open(ghostty_theme).read()
bg = re.search(r'^background = #([0-9a-f]{6})', t, re.M).group(1)
for n, h in re.findall(r'^palette = (\d+)=#([0-9a-f]{6})', t, re.M):
    r = ratio(h, bg)
    if r < 4.0:
        bad.append(f"ghostty dawn ansi {n} = {r:.2f} (< 4.0)")

if bad:
    print("\n".join(bad), file=sys.stderr)
    sys.exit(1)
print("contrast ok")
P
