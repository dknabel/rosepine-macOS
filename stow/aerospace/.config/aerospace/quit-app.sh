#!/usr/bin/env bash
# Quit the app that owns the focused window (the option-shift-m bind).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
app="$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null | head -n1)"
[ -n "$app" ] || exit 0
osascript -e 'on run argv' -e 'tell application (item 1 of argv) to quit' -e 'end run' "$app"
