#!/usr/bin/env bash
# The "keys" popup is toggled by click or by the AeroSpace hotkey (alt-shift-/).
sketchybar --add item keys right \
  --set keys icon=$'\xef\x84\x9c' icon.color="$RP_SUBTLE" label.drawing=off \
    popup.align=right popup.background.color="$RP_SURFACE" popup.background.border_width=2 \
    popup.background.border_color="$RP_OVERLAY" popup.background.corner_radius=12 \
    script="$CONFIG_DIR/plugins/cheatsheet.sh" \
    click_script="$CONFIG_DIR/plugins/cheatsheet.sh toggle" \
  --subscribe keys front_app_switched
