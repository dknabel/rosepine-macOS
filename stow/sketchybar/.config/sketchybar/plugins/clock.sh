#!/usr/bin/env bash
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
state="$HOME/.local/state/rose-pine"
src="${0%/*}/../helpers/popupwatch.c"
bin="$state/popupwatch"

# Closes the popup once the pointer leaves the clock and popup rows. The
# mouse.exited events are unreliable around popups, so a helper polls instead.
watch_popup() {
  local box
  box="$(for n in clock vitals.cpu vitals.mem vitals.disk vitals.net; do sketchybar --query "$n" 2>/dev/null; done |
    awk '/"origin"/ {gsub(/[^0-9. ,-]/, ""); split($0, o, ","); ox = o[1]+0; oy = o[2]+0}
         /"size"/ {gsub(/[^0-9. ,-]/, ""); split($0, s, ","); w = s[1]+0; h = s[2]+0
           if (w > 0) {
             if (!n++ || ox < x0) x0 = ox; if (oy < y0 || n == 1) y0 = oy
             if (ox + w > x1) x1 = ox + w; if (oy + h > y1) y1 = oy + h }}
         END {if (n) printf "%d %d %d %d", x0 - 6, y0 - 6, x1 - x0 + 12, y1 - y0 + 12}')"
  [ -n "$box" ] || return 1
  [ -x "$bin" ] && [ "$bin" -nt "$src" ] || clang -O2 -o "$bin" "$src" -framework ApplicationServices 2>/dev/null || return 1
  # shellcheck disable=SC2086
  "$bin" $box
  sketchybar --set clock popup.drawing=off 2>/dev/null
}

case "$SENDER" in
  mouse.entered)
    [ "$NAME" = clock ] || exit 0
    # Redrawing the popup re-fires mouse.entered.
    sketchybar --query clock 2>/dev/null | grep -A1 '"popup"' | grep -q '"on"' && exit 0
    sketchybar --set clock popup.drawing=on 2>/dev/null
    "${0%/*}/vitals.sh" >/dev/null 2>&1
    watch_popup </dev/null >/dev/null 2>&1 & ;;
  *)
    [ "$NAME" = clock ] && sketchybar --set clock label="$(date '+%a %b %d  %H:%M')" 2>/dev/null ;;
esac
exit 0
