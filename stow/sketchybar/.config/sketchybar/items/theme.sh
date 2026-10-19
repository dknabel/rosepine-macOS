#!/usr/bin/env bash
sketchybar --add item theme right \
  --set theme update_freq=30 icon.color="$RP_IRIS" label.drawing=off \
    script="$CONFIG_DIR/plugins/theme.sh" \
    click_script="\"\$HOME/.local/bin/rosepine-switch\" toggle"
