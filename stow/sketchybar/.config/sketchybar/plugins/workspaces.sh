#!/usr/bin/env bash
# Update one workspace item (NAME=workspace.N). Never prints errors to the bar.
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
. "$(dirname "$0")/app_icon.sh"

sid="${NAME##*.}"
focused="${FOCUSED_WORKSPACE:-}"
if [ -z "$focused" ]; then
  focused="$(aerospace list-workspaces --focused 2>/dev/null | head -n1)"
fi

icons=""
while IFS= read -r app; do
  [ -n "$app" ] || continue
  icons="$icons$(app_icon "$app")"
done <<WIN
$(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null | sort -u)
WIN

if [ "$sid" = "$focused" ]; then
  [ -n "$icons" ] || icons=" "
  sketchybar --set "$NAME" drawing=on background.drawing=on ${RP_IRIS:+background.color=$RP_IRIS} \
    ${RP_BASE:+icon.color=$RP_BASE} label="$icons" 2>/dev/null
elif [ -n "$icons" ]; then
  sketchybar --set "$NAME" drawing=on background.drawing=on ${RP_OVERLAY:+background.color=$RP_OVERLAY} \
    ${RP_TEXT:+icon.color=$RP_TEXT} label="$icons" 2>/dev/null
else
  sketchybar --set "$NAME" drawing=off 2>/dev/null
fi
exit 0
