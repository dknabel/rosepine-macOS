#!/usr/bin/env bash
sketchybar --add item github right \
  --set github update_freq=300 drawing=off icon.color="$RP_PINE" \
    script="$CONFIG_DIR/plugins/github.sh" \
    click_script="open https://github.com/notifications"
