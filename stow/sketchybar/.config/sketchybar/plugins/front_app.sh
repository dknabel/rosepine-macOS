#!/usr/bin/env bash
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
if [ "$SENDER" = "front_app_switched" ] && [ -n "$INFO" ]; then
  sketchybar --set "$NAME" label="$INFO" 2>/dev/null
fi
exit 0
