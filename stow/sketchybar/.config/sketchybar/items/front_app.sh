#!/usr/bin/env bash
sketchybar --add item front_app left \
  --set front_app icon.drawing=off label.color="$RP_SUBTLE" \
    script="$CONFIG_DIR/plugins/front_app.sh" \
  --subscribe front_app front_app_switched
