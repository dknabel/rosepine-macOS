#!/usr/bin/env bash
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
on=$'\xef\x87\xab'
off=$'\xef\x81\xb1'
ssid="$(ipconfig getsummary en0 2>/dev/null | awk -F' SSID : ' '/ SSID : /{print $2; exit}')"
case "$ssid" in "<redacted>") ssid="" ;; esac
if [ -z "$ssid" ]; then
  # Newer macOS redacts the SSID; fall back to "has an IP address".
  ip="$(ipconfig getifaddr en0 2>/dev/null)"
  [ -n "$ip" ] && ssid="Wi-Fi"
fi
if [ -n "$ssid" ]; then
  sketchybar --set "$NAME" drawing=on icon="$on" ${RP_IRIS:+icon.color=$RP_IRIS} label="$ssid" 2>/dev/null
else
  sketchybar --set "$NAME" drawing=on icon="$off" ${RP_MUTED:+icon.color=$RP_MUTED} label="Disconnected" 2>/dev/null
fi
exit 0
