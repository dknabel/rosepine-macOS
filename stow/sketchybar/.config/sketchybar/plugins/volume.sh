#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
vol="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
case "$vol" in
  ''|*[!0-9]*) sketchybar --set "$NAME" drawing=off 2>/dev/null; exit 0 ;;
esac
muted="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"
if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then
  icon=$'\xef\x80\xa6'; label="Muted"
else
  icon=$'\xef\x80\xa8'; label="$vol%"
fi
sketchybar --set "$NAME" drawing=on icon="$icon" ${RP_ROSE:+icon.color=$RP_ROSE} label="$label" 2>/dev/null
exit 0
