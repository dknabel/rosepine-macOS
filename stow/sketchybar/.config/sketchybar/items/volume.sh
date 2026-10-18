#!/usr/bin/env bash
sketchybar --add item volume right \
  --set volume update_freq=30 icon.color="$RP_ROSE" \
    script="$CONFIG_DIR/plugins/volume.sh" \
  --subscribe volume volume_change
