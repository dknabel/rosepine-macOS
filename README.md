# macOS Rosé Pine rice

Stow-managed dotfiles: Ghostty, tmux, zsh + Starship, AeroSpace, JankyBorders, SketchyBar,
themed by a `rosepine-switch` engine (Rosé Pine by night, Dawn by day).

## Install

    ./bootstrap.sh

Installs the Brewfile, dry-runs Stow (aborting on conflicts), then links `stow/*` into `$HOME`.
Re-runnable.

## Tests

    bash theme/tests/run.sh
