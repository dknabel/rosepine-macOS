#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
case "$SENDER" in
  mouse.entered)
    sketchybar --set "$NAME" popup.drawing=on 2>/dev/null
    "${0%/*}/vitals.sh" >/dev/null 2>&1 ;;
  mouse.exited.global)
    sketchybar --set "$NAME" popup.drawing=off 2>/dev/null ;;
  *)
    sketchybar --set "$NAME" label="$(date '+%a %b %d  %H:%M')" 2>/dev/null ;;
esac
exit 0
