#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
hide() { sketchybar --set "$NAME" drawing=off 2>/dev/null; exit 0; }
gh auth status >/dev/null 2>&1 || hide
count="$(gh api notifications --jq 'length' 2>/dev/null)" || hide
case "$count" in ''|*[!0-9]*|0) hide ;; esac
sketchybar --set "$NAME" drawing=on icon=$'\xef\x82\x9b' ${RP_PINE:+icon.color=$RP_PINE} label="$count" 2>/dev/null
exit 0
