#!/usr/bin/env bash
# Sourced by every plugin: brew services start SketchyBar with a minimal PATH,
# so add Homebrew's dirs for aerospace, nowplaying-cli and gh.
# SKETCHYBAR_EXTRA_PATH overrides the prefix (tests only).
export PATH="${SKETCHYBAR_EXTRA_PATH-/opt/homebrew/bin:/usr/local/bin}:$PATH"
