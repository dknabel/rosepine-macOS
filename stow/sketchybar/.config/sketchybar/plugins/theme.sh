#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
state="$HOME/.local/state/rose-pine"
mode="$(cat "$state/mode" 2>/dev/null)" || mode=main
# Self-heal: if the bar was last rendered in another mode (a missed reload), reload now.
loaded="$(cat "$state/bar.mode" 2>/dev/null)" || loaded=""
if [ -n "$loaded" ] && [ "$loaded" != "$mode" ]; then sketchybar --reload 2>/dev/null; exit 0; fi
if [ "$mode" = dawn ]; then icon=$'\xef\x86\x85'; else icon=$'\xef\x86\x86'; fi  # sun / moon
sketchybar --set "$NAME" icon="$icon" label.drawing=off \
  ${RP_IRIS:+icon.color=$RP_IRIS} 2>/dev/null
exit 0
