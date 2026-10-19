#!/usr/bin/env bash
sketchybar --add item clock right \
  --set clock update_freq=30 icon.drawing=off popup.align=right \
    popup.background.color="$RP_SURFACE" popup.background.border_width=2 \
    popup.background.border_color="$RP_OVERLAY" popup.background.corner_radius=12 \
    script="$CONFIG_DIR/plugins/clock.sh" \
  --subscribe clock mouse.entered mouse.exited.global

# Hover popup rows, filled by plugins/vitals.sh.
for row in cpu mem disk net; do
  sketchybar --add item "vitals.$row" popup.clock \
    --set "vitals.$row" drawing=off icon.color="$RP_FOAM" label.color="$RP_TEXT"
done
