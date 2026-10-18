#!/usr/bin/env bash
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
sketchybar --set "$NAME" label="$(date '+%a %b %d  %H:%M')" 2>/dev/null
exit 0
