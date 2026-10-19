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
- The first install flips the system appearance immediately (to light during the day).
- Hide the macOS menu bar (System Settings > Control Center > Automatically hide and
  show the menu bar): SketchyBar replaces it and AeroSpace leaves a 20px top gap (the notch reserves 32px more).
- Moving the repo: first run `stow -D -d stow -t ~ <packages>` from the old location,
  then re-run `./bootstrap.sh`. `rosepine-switch` reads the Starship base from the repo copy.

## Firefox start page
Stowed to `~/.config/startpage/index.html` (Rose Pine dawn 07:00-18:59, fixed hours, not sunrise-aware, main otherwise, live clock).
Set Firefox Settings > Home > Homepage to `file:///Users/<you>/.config/startpage/index.html`.
Append `?theme=dawn` or `?theme=main` to force a palette. Edit the link list in the file.
Firefox's New Tab page ignores this; use a new-tab-override extension if you want it there.

## Firefox theme
`userChrome.css`/`userContent.css` in `~/.config/firefox-theme`, linked into your default profile by
`install-firefox-theme [profile-dir]` (on PATH after stow; already run for the default profile).
It also enables `toolkit.legacyUserProfileCustomizations.stylesheets` via `user.js`. Restart Firefox.
Colors follow the system appearance, so set Firefox Settings > Extensions & Themes > System theme (auto).

## Modes
Automatic: checked every 15 minutes and at login. Without a location, dawn is 07:00-18:59
and main otherwise. With a location it follows sunrise and sunset:

    rosepine-switch location 40.7128 -74.0060     # latitude longitude (written to ~/.config/rose-pine/location)

Polar latitudes or an invalid location fall back to the fixed hours (`mode_for_hour` in `theme/lib/render.sh`).

Override by hand (holds until the automatic mode next changes):

    rosepine-switch toggle      # flip dawn/main; also bound to a click on the sun/moon item in the bar
    rosepine-switch dawn        # or: main
    rosepine-switch auto        # drop the override and re-apply the schedule
    rosepine-switch status      # e.g. "main (pinned)"

## Bar extras
- Sun/moon item (right side): click to toggle; a lock appears while an override is active.
- Hover the clock for CPU, memory, disk and network gauges.

## CLI tool themes
`rosepine-switch` also renders `fzf.sh`, `lazygit.yml` and `delta.gitconfig` into
`~/.local/state/rose-pine/`. The zsh hook applies fzf and lazygit automatically and sets `BAT_THEME=ansi`
(bat and delta take their syntax colors from the Ghostty palette). For delta, add this to your gitconfig:

    [include]
        path = ~/.local/state/rose-pine/delta.gitconfig

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
