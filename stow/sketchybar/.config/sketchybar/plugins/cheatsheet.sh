#!/usr/bin/env bash
# Keybinding cheat sheet popup built from the live AeroSpace config.
# `cheatsheet.sh toggle` (hotkey or click) opens/closes it; any app switch closes it.
. "${0%/*}/env.sh"
. "$HOME/.local/state/rose-pine/colors.sh" 2>/dev/null || true
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
item=keys

marker="$HOME/.local/state/rose-pine/cheatsheet.open"
close() { rm -f "$marker"; sketchybar --set "$item" popup.drawing=off 2>/dev/null; exit 0; }

[ "$SENDER" = front_app_switched ] && close
[ "${1:-}" = toggle ] || exit 0
[ -f "$marker" ] && close

cfg="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"
[ -f "$cfg" ] || cfg="$HOME/.aerospace.toml"
[ -f "$cfg" ] || exit 0

# Emits "H<TAB>section title" and "K<TAB>keys<TAB>description" lines. Bindings
# that differ only in their last key and argument (alt-h/j/k/l, alt-1..9) fold
# into one row.
rows="$(awk '
  function pretty(k,   n, parts, i, out, m) {
    n = split(k, parts, "-"); out = ""
    for (i = 1; i <= n; i++) {
      m = parts[i]
      if (m == "slash") m = "/"; else if (m == "comma") m = ","; else if (m == "semicolon") m = ";"
      else if (m == "period") m = "."; else if (m == "backspace") m = "⌫"; else if (m == "esc") m = "esc"
      out = out (i > 1 ? "-" : "") m
    }
    return out
  }
  function flush(   i, j, g, k, a, kv, kk, aa, n) {
    for (i = 1; i <= ng; i++) {
      g = order[i]
      if (cnt[g] >= 3 && verb[g] != "") {
        n = split(klist[g], k, ",") ; split(alist[g], a, ",")
        kk = pretty(k[1]); aa = a[1]
        for (j = 2; j <= n; j++) { kk = kk "/" pretty(k[j]); aa = aa "/" a[j] }
        if (aa == "1/2/3/4/5/6/7/8/9") aa = "1…9"
        if (kk == "1/2/3/4/5/6/7/8/9") kk = "1…9"
        printf "K\t%s%s\t%s %s\n", pretty(prefix[g]), kk, verb[g], aa
      } else {
        n = split(full[g], k, "\n")
        for (j = 1; j <= n; j++) { split(k[j], kv, "\t"); printf "K\t%s\t%s\n", pretty(kv[1]), kv[2] }
      }
    }
    ng = 0; delete cnt; delete klist; delete alist; delete full; delete order
  }
  /^\[mode\.[a-z-]+\.binding\]/ { flush(); m = $0; gsub(/^\[mode\.|\.binding\]$/, "", m); printf "H\t%s\n", m; next }
  /^\[/ { flush(); m = ""; next }
  m != "" && /^[a-z0-9-]+ *= */ {
    key = $1; cmd = $0; sub(/^[^=]*= */, "", cmd); gsub(/[\[\]\047]/, "", cmd); gsub(/, */, " + ", cmd)
    last = key; sub(/^.*-/, "", last); pre = key; if (pre == last) pre = ""; else sub(/[^-]*$/, "", pre)
    n = split(cmd, w, " "); v = ""; arg = ""
    if (n == 2 && cmd !~ /\+/) { v = w[1]; arg = w[2] }
    g = pre "|" v
    if (!(g in cnt)) { order[++ng] = g; prefix[g] = pre; verb[g] = v }
    cnt[g]++
    klist[g] = klist[g] (klist[g] == "" ? "" : ",") last
    alist[g] = alist[g] (alist[g] == "" ? "" : ",") arg
    full[g] = full[g] (full[g] == "" ? "" : "\n") key "\t" cmd
  }
  END { flush() }
' "$cfg")"

sketchybar --remove '/cheatsheet\..*/' >/dev/null 2>&1
i=0
while IFS=$'\t' read -r kind a b; do
  i=$((i + 1))
  name="cheatsheet.$i"
  if [ "$kind" = H ]; then
    sketchybar --add item "$name" popup."$item" \
      --set "$name" icon="$a mode" icon.color="${RP_GOLD:-0xfff6c177}" label.drawing=off 2>/dev/null
  else
    printf -v keys '%-22s' "$a"
    sketchybar --add item "$name" popup."$item" \
      --set "$name" icon="$keys" icon.color="${RP_IRIS:-0xffc4a7e7}" label="$b" \
        label.color="${RP_TEXT:-0xffe0def4}" 2>/dev/null
  fi
done <<< "$rows"
: > "$marker" 2>/dev/null
sketchybar --set "$item" popup.drawing=on 2>/dev/null
exit 0
