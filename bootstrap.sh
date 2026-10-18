#!/usr/bin/env bash
# Re-runnable installer. Takes no arguments.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHCTL="${LAUNCHCTL:-launchctl}"
LABEL="com.user.rosepine"

check_prereqs() {
  [ "$(uname -s)" = "Darwin" ] || { echo "error: macOS required" >&2; exit 1; }
  command -v brew >/dev/null 2>&1 || { echo "error: Homebrew not found (https://brew.sh)" >&2; exit 1; }
}

run_stow() {
  # .gitkeep placeholders must not be linked into $HOME.
  local STOW_ARGS=(-d "$REPO_DIR/stow" -t "$HOME" --ignore='^/\.gitkeep$')
  local packages=() d out
  for d in "$REPO_DIR"/stow/*/; do packages+=("$(basename "$d")"); done

  echo "Stow dry run: ${packages[*]}"
  if ! out="$(stow "${STOW_ARGS[@]}" -n --verbose "${packages[@]}" 2>&1)"; then
    echo "error: stow conflicts, aborting:" >&2
    echo "$out" >&2
    exit 1
  fi
  stow "${STOW_ARGS[@]}" --verbose "${packages[@]}"
}

install_zshrc_hook() {
  local rc="$HOME/.zshrc"
  touch "$rc"
  if grep -qF '# >>> rose-pine rice >>>' "$rc"; then return 0; fi
  cat >> "$rc" <<'BLOCK'

# >>> rose-pine rice >>>
for f in "$HOME"/.zshrc.d/*.zsh; do
  [ -r "$f" ] && source "$f"
done
unset f
# <<< rose-pine rice <<<
BLOCK
}

install_launchd_agent() {
  local src="$REPO_DIR/launchd/$LABEL.plist"
  local dest_dir="$HOME/Library/LaunchAgents"
  local dest="$dest_dir/$LABEL.plist"
  local content esc
  mkdir -p "$dest_dir" "$HOME/.local/state/rose-pine"
  shopt -u patsub_replacement 2>/dev/null || true  # bash 5.2: keep & literal
  # XML-escape HOME (& first), then substitute without sed.
  esc="$HOME"
  esc="${esc//&/&amp;}"; esc="${esc//</&lt;}"; esc="${esc//>/&gt;}"
  esc="${esc//\"/&quot;}"; esc="${esc//\'/&apos;}"
  content="$(cat "$src")"
  printf '%s\n' "${content//__HOME__/$esc}" > "$dest"
  "$LAUNCHCTL" bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  if ! "$LAUNCHCTL" bootstrap "gui/$(id -u)" "$dest"; then
    sleep "${LAUNCHD_RETRY_SLEEP:-2}"
    if ! "$LAUNCHCTL" bootstrap "gui/$(id -u)" "$dest"; then
      echo "warn: launchctl bootstrap failed for $LABEL; schedule not loaded. Retry manually:" >&2
      echo "  launchctl bootstrap gui/$(id -u) \"$dest\"" >&2
    fi
  fi
  return 0
}

start_services() {
  brew services start sketchybar || echo "warn: could not start sketchybar" >&2
  open -a AeroSpace || echo "warn: could not open AeroSpace" >&2
}

print_reminders() {
  cat <<'MSG'

Done. Remaining manual steps:
  - Run: gh auth login
  - Grant AeroSpace Accessibility (System Settings > Privacy & Security > Accessibility)
  - Accept the System Events Automation prompt the first time the appearance flips
  - If borders or ghostty theme names misbehave, see README.md Troubleshooting
MSG
}

main() {
  cd "$REPO_DIR"
  check_prereqs
  brew bundle --file Brewfile
  run_stow
  install_zshrc_hook
  install_launchd_agent
  "$HOME/.local/bin/rosepine-switch" auto || echo "warn: rosepine-switch auto failed" >&2
  start_services
  print_reminders
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
