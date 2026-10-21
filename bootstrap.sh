#!/usr/bin/env bash
# Re-runnable installer. Usage: ./bootstrap.sh [--auto|--dark|--light]
#   --auto  switch Rose Pine dark/light with the sun (default)
#   --dark  always Rose Pine (main)
#   --light always Rose Pine Dawn
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHCTL="${LAUNCHCTL:-launchctl}"
LABEL="com.user.rosepine"
VERSION="auto"

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto|--dark|--light) VERSION="${1#--}" ;;
      -h|--help) sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "error: unknown option: $1 (use --auto, --dark or --light)" >&2; exit 2 ;;
    esac
    shift
  done
}

check_prereqs() {
  [ "$(uname -s)" = "Darwin" ] || { echo "error: macOS required" >&2; exit 1; }
  command -v brew >/dev/null 2>&1 || { echo "error: Homebrew not found (https://brew.sh)" >&2; exit 1; }
  # The clock popup's pointer watcher is compiled on first use. /usr/bin/clang
  # is only a shim until the Command Line Tools are installed.
  { command -v clang >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; } ||
    { echo "error: clang not found; run: xcode-select --install" >&2; exit 1; }
}

run_stow() {
  # --no-folding: link files, not directories, so tools writing into ~/.config/*
  # never write into the repo.
  local STOW_ARGS=(-d "$REPO_DIR/stow" -t "$HOME" --no-folding)
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
  if grep -qxF '# >>> rose-pine rice >>>' "$rc"; then return 0; fi
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

remove_launchd_agent() { # fixed-mode installs need no schedule
  "$LAUNCHCTL" bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
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
  parse_args "$@"
  cd "$REPO_DIR"
  check_prereqs
  if ! brew bundle --file Brewfile; then
    echo "error: brew bundle failed. If it names an untrusted tap, run the trust command brew prints for it (e.g. for nikitabobko/tap), then re-run ./bootstrap.sh" >&2
    exit 1
  fi
  run_stow
  install_zshrc_hook
  mkdir -p "$HOME/.local/state/rose-pine"
  if [ "$VERSION" = auto ]; then install_launchd_agent; else remove_launchd_agent; fi
  "$HOME/.local/bin/rosepine-switch" lock "$VERSION" || echo "warn: rosepine-switch lock $VERSION failed" >&2
  start_services
  print_reminders
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
