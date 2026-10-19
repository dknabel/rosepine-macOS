#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
state="$HOME/.local/state/rose-pine"
mode="$(cat "$state/mode" 2>/dev/null)" || mode=main
if [ "$mode" = dawn ]; then icon=$'\xef\x86\x85'; else icon=$'\xef\x86\x86'; fi  # sun / moon
if [ -s "$state/pin" ]; then label=$'\xef\x80\xa3'; draw=on; else label=""; draw=off; fi  # lock when pinned
sketchybar --set "$NAME" icon="$icon" label="$label" label.drawing="$draw" \
  ${RP_IRIS:+icon.color=$RP_IRIS} 2>/dev/null
exit 0
