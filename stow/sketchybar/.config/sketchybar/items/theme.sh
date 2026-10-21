#!/usr/bin/env bash
sketchybar --add item theme right \
  --set theme update_freq=30 icon.color="$RP_IRIS" label.drawing=off \
    script="$CONFIG_DIR/plugins/theme.sh" \
    click_script="nohup \"\$HOME/.local/bin/rosepine-switch\" toggle >/dev/null 2>&1 &" \
  --subscribe theme system_woke
# Fixed dark/light installs have nothing to toggle.
[ ! -f "${ROSEPINE_LOCK_FILE:-$HOME/.config/rose-pine/lock}" ] || sketchybar --set theme drawing=off
