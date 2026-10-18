#!/usr/bin/env bash
# Sourced helper: app_icon "<App Name>" prints a sketchybar-app-font ligature
# such as ":safari:". Unknown apps get ":default:". This is a small map of
# common apps only; add more cases as needed (see the font's icon_map).
app_icon() {
  case "$1" in
    Ghostty) echo ":ghostty:" ;;
    Safari) echo ":safari:" ;;
    Arc) echo ":arc:" ;;
    "Google Chrome") echo ":google_chrome:" ;;
    Firefox) echo ":firefox:" ;;
    Finder) echo ":finder:" ;;
    Messages) echo ":messages:" ;;
    Mail) echo ":mail:" ;;
    Slack) echo ":slack:" ;;
    Discord) echo ":discord:" ;;
    Spotify) echo ":spotify:" ;;
    Music) echo ":music:" ;;
    Code) echo ":code:" ;;
    Notes) echo ":notes:" ;;
    Calendar) echo ":calendar:" ;;
    *) echo ":default:" ;;
  esac
}
