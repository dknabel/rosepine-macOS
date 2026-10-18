#!/usr/bin/env bash
sketchybar --add item clock right \
  --set clock update_freq=30 icon.drawing=off \
    script="$CONFIG_DIR/plugins/clock.sh"
