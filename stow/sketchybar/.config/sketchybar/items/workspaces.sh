#!/usr/bin/env bash
# One item per workspace 1..9 (aerospace does not persist empty workspaces).
for i in 1 2 3 4 5 6 7 8 9; do
  sketchybar --add item "workspace.$i" left \
    --set "workspace.$i" \
      drawing=off \
      background.drawing=on background.color="$RP_OVERLAY" background.corner_radius=8 \
      background.height=24 \
      icon="$i" icon.color="$RP_TEXT" \
      label.font="$APP_FONT:Regular:16.0" label.color="$RP_TEXT" \
      script="$CONFIG_DIR/plugins/workspaces.sh" \
    --subscribe "workspace.$i" aerospace_workspace_change front_app_switched space_windows_change
done
