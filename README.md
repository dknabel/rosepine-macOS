# macOS Rose Pine rice

Rose Pine (main at night, Dawn by day) across Ghostty, tmux, Starship, SketchyBar,
AeroSpace + JankyBorders and the system appearance. SIP stays on.

## Installed
Brewfile apps, stow packages (`stow/*` linked into `$HOME`), the `rosepine-switch`
script (`~/.local/bin`), a zsh hook (`~/.zshrc.d/*.zsh`, sourced via a marked block
appended to `~/.zshrc`) and, for `--auto` installs, a launchd agent `com.user.rosepine`.

## Install
Pick a version:

    ./bootstrap.sh --auto     # default: Rose Pine at night, Dawn by day (follows the sun)
    ./bootstrap.sh --dark     # always Rose Pine (main)
    ./bootstrap.sh --light    # always Rose Pine Dawn

Re-runnable; run it again with a different flag to switch versions. Aborts without changes if stow finds conflicts.
`--dark` and `--light` skip the launchd schedule (and remove it if a previous `--auto` install left one), hide the
sun/moon item from the bar, and make `rosepine-switch auto|toggle|dawn|main` refuse with a pointer back to `bootstrap.sh`.

If `brew bundle` fails naming an untrusted tap, run the trust command brew prints
for it (e.g. for nikitabobko/tap), then re-run `./bootstrap.sh`.

## Things to know
- The first install flips the system appearance immediately (to light for `--light`, or during the day for `--auto`).
- Hide the macOS menu bar (System Settings > Control Center > Automatically hide and
  show the menu bar): SketchyBar replaces it and AeroSpace leaves a 20px top gap (the notch reserves 32px more).
  The bar's height and side margin are derived from the AeroSpace `[gaps]` config, so changing the gaps resizes the bar.
- Moving the repo: first run `stow -D -d stow -t ~ <packages>` from the old location,
  then re-run `./bootstrap.sh`. `rosepine-switch` reads the Starship base from the repo copy.

## Firefox start page
Stowed to `~/.config/startpage/index.html` (live clock; follows the current theme via `~/.local/state/rose-pine/startpage.css`, rendered by `rosepine-switch`, so sunrise/sunset and the manual toggle apply; an open tab updates within 30s).
Set Firefox Settings > Home > Homepage to `file:///Users/<you>/.config/startpage/index.html`.
Append `?theme=dawn` or `?theme=main` to force a palette. Edit the link list in the file.
Firefox's New Tab page ignores this; use a new-tab-override extension if you want it there.

## Firefox theme
`userChrome.css`/`userContent.css` in `~/.config/firefox-theme`, linked into your default profile by
`install-firefox-theme [profile-dir]` (on PATH after stow; already run for the default profile).
It also enables `toolkit.legacyUserProfileCustomizations.stylesheets` via `user.js`. Restart Firefox.
Colors follow the system appearance, so set Firefox Settings > Extensions & Themes > System theme (auto).

## Modes
This section applies to `--auto` installs; `--dark` and `--light` stay on one palette.

Automatic: checked every 15 minutes, at login and on wake from sleep. Without a location, dawn is 07:00-18:59
and main otherwise. With a location it follows sunrise and sunset:

    rosepine-switch location 40.7128 -74.0060     # latitude longitude (written to ~/.config/rose-pine/location)

Polar latitudes or an invalid location fall back to the fixed hours (`mode_for_hour` in `theme/lib/render.sh`).

Override by hand (holds until the automatic mode next changes):

    rosepine-switch toggle      # flip dawn/main; also bound to a click on the sun/moon item in the bar
    rosepine-switch dawn        # or: main
    rosepine-switch auto        # drop the override and re-apply the schedule
    rosepine-switch status      # e.g. "main (pinned)"

## Bar extras
- Sun/moon item (right side, `--auto` installs only): click to toggle (the override holds until the next sunrise/sunset).
- Hover the clock for CPU, memory, disk and network gauges.
- Workspace pills show the apps in each workspace; the number gains a window count (e.g. `3·2`) once it holds more than one window.
- Keybinding cheat sheet: `option-shift-/` (or click the keyboard icon). It is built from your live
  `aerospace.toml`, so new bindings show up automatically; any app switch closes it.

## Keybindings
Hyprland-style, with option as the modifier. The cheat sheet has the full live list; the main ones:

| Keys | Action |
| --- | --- |
| `option-q` / `option-e` / `option-r` | new terminal / file manager / Spotlight |
| `option-c` / `option-shift-m` | close window / quit app |
| `option-v` / `option-j` / `option-comma` / `option-f` | floating / split / accordion / fullscreen |
| `option-ctrl-arrows` | focus (plain option-arrows stay word-jump in text fields) |
| `option-ctrl-shift-arrows` | move window |
| `option-1..9`, `option-0` | workspaces 1-10 |
| `option-s` | scratchpad workspace S |
| `option-shift-<n>` / `option-shift-s` | send window to workspace / scratchpad |

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
