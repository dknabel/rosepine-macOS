#!/usr/bin/env bash
sketchybar --add item media center \
  --set media update_freq=5 drawing=off icon.color="$RP_GOLD" label.color="$RP_GOLD" \
    script="$CONFIG_DIR/plugins/media.sh"
