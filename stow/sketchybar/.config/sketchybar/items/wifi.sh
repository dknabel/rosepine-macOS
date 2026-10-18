#!/usr/bin/env bash
sketchybar --add item wifi right \
  --set wifi update_freq=30 icon.color="$RP_IRIS" \
    script="$CONFIG_DIR/plugins/wifi.sh" \
  --subscribe wifi wifi_change system_woke
