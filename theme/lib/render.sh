# Rose Pine renderers. Source after a palette (RP_* vars). Bash 3.2 compatible.

RP_NAMES="BASE SURFACE OVERLAY MUTED SUBTLE TEXT LOVE GOLD ROSE PINE FOAM IRIS"

_rp_val() { eval "printf '%s' \"\${RP_$1}\""; }
_rp_lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

mode_for_hour() {
  local h=$((10#$1))
  if [ "$h" -ge 7 ] && [ "$h" -le 18 ]; then echo dawn; else echo main; fi
}

render_colors_sh() {
  local n
  { for n in $RP_NAMES; do echo "export RP_$n=0xff$(_rp_val "$n")"; done; } > "$1"
}

render_tmux() {
  local c
  c() { printf '#%s' "$(_rp_val "$1")"; }
  {
    echo "set -g status-style \"bg=$(c BASE),fg=$(c TEXT)\""
    echo "set -g message-style \"bg=$(c OVERLAY),fg=$(c TEXT)\""
    echo "set -g pane-border-style \"fg=$(c MUTED)\""
    echo "set -g pane-active-border-style \"fg=$(c IRIS)\""
    echo "set -g status-left-style \"fg=$(c ACCENT_TEXT)\""
    echo "set -g status-right-style \"fg=$(c DIM_TEXT)\""
    echo "set -g window-status-style \"fg=$(c DIM_TEXT)\""
    echo "set -g window-status-current-style \"fg=$(c HILITE_TEXT),bold\""
    echo "set -g mode-style \"bg=$(c OVERLAY),fg=$(c MARK_TEXT)\""
  } > "$1"
}

# Top-level keys (palette, and base.toml's add_newline/format) must precede any
# [table] header, or TOML assigns them to that table. So the palette table goes last.
render_starship() {
  local n
  {
    echo 'palette = "rp"'
    echo
    cat "$2"
    echo
    echo '[palettes.rp]'
    for n in $RP_NAMES ON_ACCENT PROMPT_OK; do echo "$(_rp_lower "$n") = \"#$(_rp_val "$n")\""; done
  } > "$1"
}
