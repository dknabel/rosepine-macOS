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

# _rp_mix <fg hex> <bg hex> <fg percent>: blend two RRGGBB colors, prints RRGGBB.
_rp_mix() {
  local i out="" a b
  for i in 0 2 4; do
    a=$((16#${1:$i:2})); b=$((16#${2:$i:2}))
    out="$out$(printf '%02x' $(( (a * $3 + b * (100 - $3)) / 100 )))"
  done
  printf '%s' "$out"
}

# Sourced by zsh: fzf picks its palette from FZF_DEFAULT_OPTS.
render_fzf() {
  local c
  c() { printf '#%s' "$(_rp_val "$1")"; }
  {
    printf 'export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS_BASE:-} '
    printf -- '--color=bg:-1,bg+:%s,fg:%s,fg+:%s,hl:%s,hl+:%s,' "$(c OVERLAY)" "$(c TEXT)" "$(c TEXT)" "$(c ACCENT_TEXT)" "$(c ACCENT_TEXT)"
    printf -- 'info:%s,prompt:%s,pointer:%s,marker:%s,spinner:%s,header:%s,border:%s,gutter:-1"\n' \
      "$(c DIM_TEXT)" "$(c FOAM)" "$(c HILITE_TEXT)" "$(c PINE)" "$(c MARK_TEXT)" "$(c DIM_TEXT)" "$(c MUTED)"
  } > "$1"
}

# lazygit reads this as an extra config file (LG_CONFIG_FILE).
render_lazygit() {
  local c
  c() { printf "'#%s'" "$(_rp_val "$1")"; }
  {
    echo "gui:"
    echo "  theme:"
    echo "    activeBorderColor: [$(c ACCENT_TEXT), bold]"
    echo "    inactiveBorderColor: [$(c MUTED)]"
    echo "    searchingActiveBorderColor: [$(c MARK_TEXT), bold]"
    echo "    optionsTextColor: [$(c FOAM)]"
    echo "    selectedLineBgColor: [$(c OVERLAY)]"
    echo "    inactiveViewSelectedLineBgColor: [$(c SURFACE)]"
    echo "    cherryPickedCommitFgColor: [$(c ACCENT_TEXT)]"
    echo "    cherryPickedCommitBgColor: [$(c OVERLAY)]"
    echo "    markedBaseCommitFgColor: [$(c MARK_TEXT)]"
    echo "    unstagedChangesColor: [$(c LOVE)]"
    echo "    defaultFgColor: [$(c TEXT)]"
  } > "$1"
}

# git-delta feature file: add `[include] path = ~/.local/state/rose-pine/delta.gitconfig`.
# Syntax colors come from the terminal's ANSI palette (syntax-theme = ansi) so
# they follow Ghostty's light/dark theme automatically.
render_delta() {
  local light=false minus plus
  [ "$RP_BASE" = faf4ed ] && light=true
  minus="$(_rp_mix "$(_rp_val LOVE)" "$(_rp_val BASE)" 22)"
  plus="$(_rp_mix "$(_rp_val PINE)" "$(_rp_val BASE)" 22)"
  {
    echo "[delta]"
    echo "    syntax-theme = ansi"
    echo "    light = $light"
    echo "    dark = $([ "$light" = true ] && echo false || echo true)"
    echo "    minus-style = syntax \"#$minus\""
    echo "    minus-emph-style = syntax \"#$(_rp_mix "$(_rp_val LOVE)" "$(_rp_val BASE)" 40)\""
    echo "    plus-style = syntax \"#$plus\""
    echo "    plus-emph-style = syntax \"#$(_rp_mix "$(_rp_val PINE)" "$(_rp_val BASE)" 40)\""
    echo "    file-style = bold \"#$(_rp_val ACCENT_TEXT)\""
    echo "    hunk-header-style = file line-number syntax"
    echo "    hunk-header-decoration-style = \"#$(_rp_val MUTED)\" box"
    echo "    line-numbers-minus-style = \"#$(_rp_val LOVE)\""
    echo "    line-numbers-plus-style = \"#$(_rp_val PINE)\""
    echo "    line-numbers-zero-style = \"#$(_rp_val DIM_TEXT)\""
  } > "$1"
}
