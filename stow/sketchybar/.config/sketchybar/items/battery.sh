#!/usr/bin/env bash
sketchybar --add item battery right \
  --set battery update_freq=120 drawing=off icon.color="$RP_FOAM" \
    script="$CONFIG_DIR/plugins/battery.sh" \
  --subscribe battery system_woke power_source_change
