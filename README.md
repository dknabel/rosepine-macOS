# macOS Rose Pine rice

Rose Pine (main at night, Dawn by day) across Ghostty, tmux, Starship, SketchyBar,
AeroSpace + JankyBorders and the system appearance. SIP stays on.

## Installed
Brewfile apps, stow packages (`stow/*` linked into `$HOME`), the `rosepine-switch`
script (`~/.local/bin`), a zsh hook (`~/.zshrc.d/*.zsh`, sourced via a marked block
appended to `~/.zshrc`) and a launchd agent `com.user.rosepine`.

## Install
    ./bootstrap.sh
Re-runnable. Aborts without changes if stow finds conflicts.

## Modes
Automatic: 07:00 and 19:00 and at login (dawn 07-18, main otherwise).
Force one: `rosepine-switch dawn` or `rosepine-switch main` (`auto` re-applies the schedule).

## Changing the switch hours
Edit `StartCalendarInterval` in `launchd/com.user.rosepine.plist` AND `mode_for_hour`
in `theme/lib/render.sh`, then re-run `./bootstrap.sh`.

## Permissions
- `gh auth login`
- AeroSpace: Accessibility
- System Events Automation prompt on the first appearance flip

## Troubleshooting
- Ghostty theme names: `ghostty +list-themes | grep -i rose-pine`
- AeroSpace config errors: `aerospace reload-config`
- borders not starting: check PATH (Homebrew `/opt/homebrew/bin`) for the launching shell
- Switch log: `~/.local/state/rose-pine/switch.log`

## Tests
    bash theme/tests/run.sh
