#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
hide() { sketchybar --set "$NAME" drawing=off 2>/dev/null; exit 0; }
out="$(nowplaying-cli get title artist 2>/dev/null)" || hide
title="$(printf '%s\n' "$out" | sed -n 1p)"
artist="$(printf '%s\n' "$out" | sed -n 2p)"
for v in title artist; do
  eval "x=\$$v"
  case "$x" in null|NULL|"(null)") eval "$v=''" ;; esac
done
[ -n "$title" ] || hide
if [ -n "$artist" ]; then text="$artist - $title"; else text="$title"; fi
if [ "${#text}" -gt 40 ]; then text="${text:0:37}..."; fi
sketchybar --set "$NAME" drawing=on icon=$'\xef\x80\x81' ${RP_GOLD:+icon.color=$RP_GOLD label.color=$RP_GOLD} label="$text" 2>/dev/null
exit 0
