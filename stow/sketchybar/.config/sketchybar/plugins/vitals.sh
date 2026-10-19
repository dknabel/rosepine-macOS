#!/usr/bin/env bash
# Fills the clock's hover popup with CPU, memory, disk and network gauges.
# Each row hides itself when its data source is unavailable.
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
state="$HOME/.local/state/rose-pine"

gauge() { # gauge <pct>: eight-segment bar
  local n=$(( ($1 * 8 + 50) / 100 )) i out=""
  [ "$n" -gt 8 ] && n=8
  for ((i = 0; i < 8; i++)); do
    if [ "$i" -lt "$n" ]; then out="$out▰"; else out="$out▱"; fi
  done
  printf '%s' "$out"
}
color() { # color <pct>: foam, gold above 60, love above 85
  if [ "$1" -ge 85 ]; then printf '%s' "$RP_LOVE"
  elif [ "$1" -ge 60 ]; then printf '%s' "$RP_GOLD"
  else printf '%s' "$RP_FOAM"; fi
}
row() { # row <name> <label> [pct]
  local name="vitals.$1" pct="$3"
  if [ -n "$pct" ]; then
    sketchybar --set "$name" drawing=on label="$2" ${RP_TEXT:+label.color=$RP_TEXT} \
      ${RP_FOAM:+icon.color=$(color "$pct")} icon="$(gauge "$pct")" 2>/dev/null
  else
    sketchybar --set "$name" drawing=on label="$2" icon="" 2>/dev/null
  fi
}
hide() { sketchybar --set "vitals.$1" drawing=off 2>/dev/null; }
isnum() { case "$1" in ''|*[!0-9]*) return 1 ;; esac; }

# CPU: summed per-process %CPU over core count.
ncpu="$(sysctl -n hw.ncpu 2>/dev/null)"
cpu="$(ps -A -o %cpu= 2>/dev/null | awk -v n="${ncpu:-0}" '{s += $1} END {if (n > 0 && NR > 0) printf "%d", s / n}')"
if isnum "$cpu"; then [ "$cpu" -gt 100 ] && cpu=100; row cpu "CPU  $cpu%" "$cpu"; else hide cpu; fi

# Memory: (active + wired + compressed) / total.
total="$(sysctl -n hw.memsize 2>/dev/null)"
mem="$(vm_stat 2>/dev/null | awk -v total="${total:-0}" '
  /page size of/ {ps = $8}
  /Pages active/ {a = $3} /Pages wired down/ {w = $4} /occupied by compressor/ {c = $5}
  END {if (total > 0 && ps > 0) printf "%d", (a + w + c) * ps * 100 / total}')"
if isnum "$mem"; then [ "$mem" -gt 100 ] && mem=100; row mem "MEM  $mem%" "$mem"; else hide mem; fi

# Disk: used share of the data volume.
disk="$(df -k /System/Volumes/Data 2>/dev/null | awk 'NR == 2 {gsub("%", "", $5); print $5}')"
if isnum "$disk"; then row disk "DSK  $disk%" "$disk"; else hide disk; fi

# Network: rate since the previous sample (stored between hovers).
human() { # bytes/sec -> short string
  awk -v b="$1" 'BEGIN {
    if (b >= 1048576) printf "%.1fM", b / 1048576
    else if (b >= 1024) printf "%dK", b / 1024
    else printf "%dB", b }'
}
iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
bytes=""
[ -n "$iface" ] && bytes="$(netstat -ib -I "$iface" 2>/dev/null | awk '$3 ~ /^<Link/ {print $(NF-4), $(NF-1); exit}')"
rx="${bytes% *}"; tx="${bytes#* }"
if isnum "$rx" && isnum "$tx"; then
  now="$(date +%s)"
  prev="$(cat "$state/net.sample" 2>/dev/null)"
  printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state/net.sample" 2>/dev/null
  read -r pt prx ptx <<< "$prev"
  if isnum "$pt" && isnum "$prx" && isnum "$ptx" && [ "$now" -gt "$pt" ] && [ "$rx" -ge "$prx" ] && [ "$tx" -ge "$ptx" ]; then
    dt=$((now - pt))
    row net "NET  ↓$(human $(( (rx - prx) / dt )))  ↑$(human $(( (tx - ptx) / dt )))"
  else
    row net "NET  ↓–  ↑–"
  fi
else
  hide net
fi
exit 0
