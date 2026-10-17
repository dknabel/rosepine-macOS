#!/usr/bin/env bash
# Re-runnable installer. Takes no arguments.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

[ "$(uname -s)" = "Darwin" ] || { echo "error: macOS required" >&2; exit 1; }
command -v brew >/dev/null 2>&1 || { echo "error: Homebrew not found (https://brew.sh)" >&2; exit 1; }

brew bundle --file Brewfile

# .gitkeep placeholders must not be linked into $HOME.
STOW_ARGS=(-d stow -t "$HOME" --ignore='^/\.gitkeep$')
packages=()
for d in stow/*/; do packages+=("$(basename "$d")"); done

echo "Stow dry run: ${packages[*]}"
if ! out="$(stow "${STOW_ARGS[@]}" -n --verbose "${packages[@]}" 2>&1)"; then
  echo "error: stow conflicts, aborting:" >&2
  echo "$out" >&2
  exit 1
fi

stow "${STOW_ARGS[@]}" --verbose "${packages[@]}"
echo "Done."
