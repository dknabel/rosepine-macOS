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

If `brew bundle` fails naming an untrusted tap, run the trust command brew prints
for it (e.g. for nikitabobko/tap), then re-run `./bootstrap.sh`.

## Things to know
- The first install flips the system appearance immediately (to light if run 07:00-18:59).
- Hide the macOS menu bar (System Settings > Control Center > Automatically hide and
  show the menu bar): SketchyBar replaces it and AeroSpace reserves 50px at the top.
- Moving the repo: first run `stow -D -d stow -t ~ <packages>` from the old location,
  then re-run `./bootstrap.sh`. `rosepine-switch` reads the Starship base from the repo copy.

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
- Ghostty theme names: `ghostty +list-themes | grep -i rose` (expects `Rose Pine`, `Rose Pine Dawn`)
- AeroSpace config errors: `aerospace reload-config`
- borders not starting: check PATH (Homebrew `/opt/homebrew/bin`) for the launching shell
- Switch log: `~/.local/state/rose-pine/switch.log`

## Tests
    bash theme/tests/run.sh
