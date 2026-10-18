#!/usr/bin/env bash
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
batt="$(pmset -g batt 2>/dev/null)"
pct="$(printf '%s\n' "$batt" | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
case "$pct" in
  ''|*[!0-9]*) sketchybar --set "$NAME" drawing=off 2>/dev/null; exit 0 ;;
esac
icon=$'\xef\x89\x80'
[ "$pct" -lt 50 ] && icon=$'\xef\x89\x83'
printf '%s' "$batt" | grep -q 'AC Power' && icon=$'\xef\x83\xa7'
if [ "$pct" -lt 20 ]; then col="$RP_LOVE"; else col="$RP_FOAM"; fi
sketchybar --set "$NAME" drawing=on icon="$icon" ${col:+icon.color=$col} label="$pct%" 2>/dev/null
exit 0
