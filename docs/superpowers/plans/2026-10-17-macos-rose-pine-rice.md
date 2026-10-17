# macOS Rosé Pine Rice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A stow-managed dotfiles repo that gives macOS a cohesive r/unixporn-style rice in Rosé Pine (main at night, Dawn by day), switched on a fixed schedule.

**Architecture:** Palettes live in the repo as shell files. One script, `rosepine-switch`, renders generated theme files into `~/.local/state/rose-pine/`, reloads each running tool, and flips macOS system appearance. A launchd agent runs it at 07:00 and 19:00 and at login. Each tool's config reads either the generated files or follows the system appearance.

**Tech Stack:** bash/zsh, GNU Stow, Homebrew (Brewfile), AeroSpace, SketchyBar + sketchybar-app-font, JankyBorders, Ghostty, tmux, Starship, launchd, `gh`, `jq`.

**Spec:** None exists as a separate document. The binding decisions come from the design interview and are recorded under Global Constraints. Rulings made without a spec are provisional.

## Global Constraints

- SIP stays fully on. No yabai, no scripting addition.
- Window manager is AeroSpace. Focus border is JankyBorders. Gaps are 10px inner and outer.
- Launcher is stock Spotlight (no Raycast or Alfred). Wallpaper is not touched.
- Palette is Rosé Pine only. Dark mode is **main**, light mode is **Dawn**. Moon is not used.
- Switch times are fixed: Dawn from 07:00 to 18:59, main from 19:00 to 06:59.
- The switch also sets macOS system appearance (dark during main, light during Dawn).
- Themed tools: Ghostty, tmux, zsh + Starship, SketchyBar, JankyBorders. Nothing else (no Neovim, btop, bat, fzf, lazygit).
- Bar: rounded SketchyBar. AeroSpace workspaces show app icons via `sketchybar-app-font`. Also shows front app, clock, battery, wifi and volume. Also a media now-playing widget and a GitHub notifications widget (needs `gh auth`).
- Focused-window border uses the palette's iris color. Unfocused uses muted. Border width 4, rounded style.
- Layout: repo root is `/Users/drew/Projects/macOS-styling`. Packages are Stow directories that mirror `$HOME`. One `Brewfile`. One `bootstrap.sh`.
- Palette hex values (no `#`):

| name | main | dawn |
|---|---|---|
| base | 191724 | faf4ed |
| surface | 1f1d2e | fffaf3 |
| overlay | 26233a | f2e9e1 |
| muted | 6e6a86 | 9893a5 |
| subtle | 908caa | 797593 |
| text | e0def4 | 575279 |
| love | eb6f92 | b4637a |
| gold | f6c177 | ea9d34 |
| rose | ebbcba | d7827e |
| pine | 31748f | 286983 |
| foam | 9ccfd8 | 56949f |
| iris | c4a7e7 | 907aa9 |

## Review Focus

1. Login or wake after 19:00 (or before 07:00) must produce main, not stay on Dawn. The schedule runs at login too and decides by the clock, not by "which trigger fired".
2. The switch runs when SketchyBar, borders, tmux or Ghostty are not running. Reload steps must be no-ops, not failures.
3. macOS blocks the System Events automation prompt. The switch must still finish the other themes and exit 0 with a warning.
4. A file Stow wants to link already exists in `~/.config`. The bootstrap must stop and name the conflict instead of overwriting it.
5. Widgets on hardware that lacks the input: no battery (desktop Mac), Spotify and Music not running, `gh` not authenticated, no wifi. Each widget must hide or show a neutral value, never an error string.

## File Structure

```
Brewfile
bootstrap.sh                      # brew bundle, stow, install launchd agent, first switch
README.md
.gitignore
theme/
  palettes/main.sh                # RP_BASE=191724 ... (one var per table row, upper-case)
  palettes/dawn.sh
  lib/render.sh                   # render_* functions, sourced by rosepine-switch
  bin/rosepine-switch             # entry point, installed to ~/.local/bin by Stow
  tests/                          # plain bash tests, run with theme/tests/run.sh
launchd/com.user.rosepine.plist   # copied (not stowed) into ~/Library/LaunchAgents
stow/
  theme/.local/bin/rosepine-switch      # symlink target for theme/bin
  ghostty/.config/ghostty/config
  tmux/.config/tmux/tmux.conf
  zsh/.zshrc.d/rosepine.zsh             # sets STARSHIP_CONFIG, inits starship
  starship/.config/starship/base.toml
  aerospace/.config/aerospace/aerospace.toml
  borders/.config/borders/bordersrc
  sketchybar/.config/sketchybar/{sketchybarrc,items/*.sh,plugins/*.sh}
```

Generated at runtime, never committed: `~/.local/state/rose-pine/{mode,colors.sh,tmux.conf,starship.toml}`.

---

### Task 1: Repo scaffold and Brewfile

**Files:**
- Create: `.gitignore`, `Brewfile`, `README.md`, `bootstrap.sh`, `theme/tests/run.sh`
- Create: empty Stow package dirs listed in File Structure

**Interfaces:**
- Produces: `theme/tests/run.sh` runs every `theme/tests/test_*.sh` and exits non-zero on the first failure. `bootstrap.sh` takes no arguments and is re-runnable.

- [ ] **Step 1: Initialize git** with `git init` in the project root, and add `.gitignore` containing `.superpowers/` and `.DS_Store`.
- [ ] **Step 2: Write `Brewfile`** with taps `nikitabobko/tap`, `FelixKratz/formulae`. Casks: `nikitabobko/tap/aerospace`, `ghostty`, `font-hack-nerd-font`, `font-sketchybar-app-font`. Formulae: `felixkratz/formulae/sketchybar`, `felixkratz/formulae/borders`, `stow`, `tmux`, `starship`, `jq`, `gh`, `switchaudio-osx`, `nowplaying-cli`.
- [ ] **Step 3: Write `theme/tests/run.sh`** to loop over `test_*.sh` files in its own directory, running each with `bash`. Add a first test, `test_smoke.sh`, that asserts `bash -n bootstrap.sh` succeeds.
- [ ] **Step 4: Write `bootstrap.sh`** (`set -euo pipefail`). Order: verify macOS and Homebrew present, `brew bundle --file Brewfile`, run `stow -d stow -t "$HOME" -n --verbose <each package>` as a dry run and abort listing any conflicts, then run stow for real. The launchd and first-switch steps are added in Task 6.
- [ ] **Step 5: Verify.** Run `bash theme/tests/run.sh`. Expected: smoke test passes, exit 0.
- [ ] **Step 6: Commit** `chore: scaffold repo, brewfile, bootstrap`.

---

### Task 2: Theme engine (`rosepine-switch`)

**Files:**
- Create: `theme/palettes/main.sh`, `theme/palettes/dawn.sh`, `theme/lib/render.sh`, `theme/bin/rosepine-switch`
- Create: `stow/theme/.local/bin/rosepine-switch` (relative symlink to `theme/bin/rosepine-switch`)
- Test: `theme/tests/test_render.sh`, `theme/tests/test_mode.sh`

**Interfaces:**
- Produces, in `theme/lib/render.sh` (all take a destination file as `$1` and read the `RP_*` variables from the current environment):
  - `mode_for_hour <hour 0-23>` prints `dawn` for 7..18, else `main`.
  - `render_colors_sh <dest>` writes `export RP_<NAME>=0xffRRGGBB` lines (ARGB, for SketchyBar and borders).
  - `render_tmux <dest>` writes tmux `set -g` style lines using `#RRGGBB`.
  - `render_starship <dest> <base.toml>` writes `palette = "rp"`, then `[palettes.rp]` with all twelve names as `#RRGGBB`, then the contents of `base.toml`.
- Produces: `rosepine-switch [auto|main|dawn]` (default `auto`, which uses `mode_for_hour "$(date +%H)"`). Honors `ROSEPINE_STATE_DIR` (default `~/.local/state/rose-pine`) and `ROSEPINE_DRY_RUN=1` (render only, no reloads, no appearance change).

- [ ] **Step 1: Write the palette files** with the table above as `RP_BASE=191724` etc., using the exact hex values.
- [ ] **Step 2: Write failing tests.** In `test_mode.sh`: `mode_for_hour 6` is `main`, `7` is `dawn`, `18` is `dawn`, `19` is `main`, `0` is `main`, `23` is `main`. In `test_render.sh`: with the dawn palette sourced, `render_colors_sh` output contains `export RP_IRIS=0xff907aa9`. `render_tmux` output contains `#faf4ed`. `render_starship` output's first line is `palette = "rp"`, it contains `base = "#faf4ed"`, and it ends with the contents of a fixture base file.
- [ ] **Step 3: Run tests, expect FAIL** (`bash theme/tests/run.sh`; functions undefined).
- [ ] **Step 4: Implement `render.sh`** to satisfy the signatures above.
- [ ] **Step 5: Run tests, expect PASS.**
- [ ] **Step 6: Implement `rosepine-switch`.** Steps in order: resolve mode, source the palette, render the three files into the state dir (atomically via temp file and `mv`), write `mode`, then (unless `ROSEPINE_DRY_RUN=1`) reload. Reloads: set appearance with `osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to <true|false>'`. If it fails, print a warning to stderr and continue. Run `tmux source-file ~/.local/state/rose-pine/tmux.conf` only if `tmux ls` succeeds. Run `borders active_color=$RP_IRIS inactive_color=$RP_MUTED` only if `pgrep -x borders`. Run `sketchybar --reload` only if `pgrep -x sketchybar`. The script exits 0 whenever the render step succeeded.
- [ ] **Step 7: Add a test** `test_switch.sh` that runs `ROSEPINE_DRY_RUN=1 ROSEPINE_STATE_DIR=$(mktemp -d) rosepine-switch dawn`, then asserts the four files exist, `mode` contains `dawn`, and a second run with `main` flips `mode` and `colors.sh`. Expect PASS.
- [ ] **Step 8: Commit** `feat: rosepine-switch theme engine`.

---

### Task 3: Ghostty, tmux, zsh + Starship

**Files:**
- Create: `stow/ghostty/.config/ghostty/config`, `stow/tmux/.config/tmux/tmux.conf`, `stow/zsh/.zshrc.d/rosepine.zsh`, `stow/starship/.config/starship/base.toml`

**Interfaces:**
- Consumes: generated `~/.local/state/rose-pine/tmux.conf` and `starship.toml` from Task 2.
- Produces: `rosepine.zsh` exports `STARSHIP_CONFIG=$HOME/.local/state/rose-pine/starship.toml` and runs `eval "$(starship init zsh)"`.

- [ ] **Step 1: Ghostty config.** `theme = light:rose-pine-dawn,dark:rose-pine`, plus font family `Hack Nerd Font`, size 14, `window-padding-x = 12`, `window-padding-y = 8`, `background-opacity = 0.95`. Ghostty follows system appearance, so the switch needs no Ghostty reload. Verify the theme names exist with `ghostty +list-themes | grep -i rose-pine`. Expected: both `rose-pine` and `rose-pine-dawn` are listed. If a name differs, use the listed one.
- [ ] **Step 2: tmux.conf.** Set `default-terminal "tmux-256color"`, mouse on, base-index 1, prefix `C-a`, and `source-file ~/.local/state/rose-pine/tmux.conf` guarded with `if-shell "test -f ..."`. The generated file (Task 2 `render_tmux`) sets `status-style`, `pane-border-style`, `pane-active-border-style` (iris), `message-style` and `window-status-*` using palette colors.
- [ ] **Step 3: Starship `base.toml`.** Left prompt: directory (`color = "iris"` style via `fg:iris`), git branch (`foam`), git status (`love`), character (`rose` on success, `love` on error). One line, rounded-feeling with `` separators. Colors reference only palette names from `[palettes.rp]`. No hex literals in this file.
- [ ] **Step 4: `rosepine.zsh`** per the Interfaces block. Add a guard: if the generated starship file is missing, run `rosepine-switch auto` once before init.
- [ ] **Step 5: Verify (automated part).** Run `ROSEPINE_STATE_DIR=$(mktemp -d) STARSHIP_CONFIG=... starship prompt` using a dry-run render. Expected: prompt renders, exit 0, no "unknown palette color" warning. Run `tmux -f stow/tmux/.config/tmux/tmux.conf start-server \; kill-server` with a rendered state file present. Expected: no errors.
- [ ] **Step 6: Verify (visual part).** After bootstrap in Task 6, open Ghostty and tmux in both modes and confirm the colors by eye. Record the outcome in the task report.
- [ ] **Step 7: Commit** `feat: ghostty, tmux, starship theming`.

---

### Task 4: AeroSpace and JankyBorders

**Files:**
- Create: `stow/aerospace/.config/aerospace/aerospace.toml`, `stow/borders/.config/borders/bordersrc` (executable)

**Interfaces:**
- Consumes: `~/.local/state/rose-pine/colors.sh` (`RP_IRIS`, `RP_MUTED`).
- Produces: AeroSpace fires `sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE` on workspace change. Task 5 subscribes to the `aerospace_workspace_change` event. Workspaces are named `1`..`9`.

- [ ] **Step 1: `aerospace.toml`.** `start-at-login = true`, `default-root-container-layout = 'tiles'`, `accordion-padding = 30`, gaps inner and outer all 10 with the outer top set to 50 to leave room for the bar. Keybindings: `alt-h/j/k/l` focus, `alt-shift-h/j/k/l` move, `alt-1..9` switch workspace, `alt-shift-1..9` move window to workspace, `alt-f` fullscreen, `alt-slash` toggle layout, `alt-shift-semicolon` service mode. Add `exec-on-workspace-change = ['/bin/bash', '-c', 'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE']`. Add `after-startup-command = ['exec-and-forget borders']`.
- [ ] **Step 2: `bordersrc`.** `source "$HOME/.local/state/rose-pine/colors.sh"` (skip with a stderr note if missing), then `borders style=round width=4.0 hidpi=on active_color=$RP_IRIS inactive_color=$RP_MUTED`.
- [ ] **Step 3: Verify.** Run `aerospace --config-path stow/aerospace/.config/aerospace/aerospace.toml` validation if available (`aerospace reload-config --dry-run`, otherwise start AeroSpace and confirm no config error dialog). Run `bash -n stow/borders/.config/borders/bordersrc`. Expected: both succeed.
- [ ] **Step 4: Commit** `feat: aerospace and borders config`.

---

### Task 5: SketchyBar

**Files:**
- Create: `stow/sketchybar/.config/sketchybar/sketchybarrc`
- Create: `.../items/{workspaces,front_app,clock,battery,wifi,volume,media,github}.sh`
- Create: `.../plugins/{workspaces,front_app,clock,battery,wifi,volume,media,github}.sh`

**Interfaces:**
- Consumes: `colors.sh` (all `RP_*` as ARGB), the `aerospace_workspace_change` event with `FOCUSED_WORKSPACE`.
- Produces: each `items/X.sh` defines its item(s) and subscribes its plugin. Each `plugins/X.sh` updates its item with `sketchybar --set "$NAME"` and takes everything else from SketchyBar's environment. Plugins never print errors to the bar.

- [ ] **Step 1: `sketchybarrc`.** Source `colors.sh`. Bar: `position=top height=36 y_offset=6 margin=10 corner_radius=12 padding_left=10 padding_right=10 color=$RP_SURFACE border_width=2 border_color=$RP_OVERLAY blur_radius=20`. Defaults: font `Hack Nerd Font:Regular:14.0`, icon color `$RP_TEXT`, label color `$RP_TEXT`. Register `--add event aerospace_workspace_change`. Source each `items/*.sh`. Finish with `sketchybar --update`.
- [ ] **Step 2: Workspaces.** One item per workspace `1..9` showing the app icons from `aerospace list-windows --workspace N --format '%{app-name}'` mapped through `sketchybar-app-font` (use the font's `:default:` glyph fallback). Focused workspace gets `$RP_IRIS` background, others `$RP_OVERLAY`. Workspaces with no windows and not focused are hidden (`drawing=off`).
- [ ] **Step 3: Left and right items.** Front app (left, label from `$INFO`). Right side from the edge inward: clock (`%a %b %d  %H:%M`), battery, wifi, volume. Battery uses `pmset -g batt` and hides the item (`drawing=off`) when no battery is present. Wifi shows the SSID or a "disconnected" glyph. Volume uses `osascript -e 'output volume of (get volume settings)'` and shows a muted glyph when muted. Icon colors: battery `foam` (`love` under 20%), wifi `iris`, volume `rose`.
- [ ] **Step 4: Media widget.** `nowplaying-cli get title artist` every 5s. Show `artist - title` truncated at 40 characters in `$RP_GOLD`. Hide the item (`drawing=off`) when nothing is playing or the command returns null.
- [ ] **Step 5: GitHub widget.** Every 5 minutes run `gh api notifications --jq 'length'`. Show the count with the GitHub glyph in `$RP_PINE`. Hide the item when the count is 0, or when `gh auth status` fails. Click opens `https://github.com/notifications`.
- [ ] **Step 6: Tests.** `theme/tests/test_sketchybar_plugins.sh` runs each plugin with `sketchybar` shadowed by a stub on `PATH` that records its arguments, and with `pmset`, `nowplaying-cli` and `gh` stubs that return the "no data" cases (no battery, null title, auth failure). Assert every plugin exits 0 and the media, github and battery stubs receive `drawing=off`.
- [ ] **Step 7: Verify.** Run `bash theme/tests/run.sh` (expect PASS) and `bash -n` on every script. Visual check of both modes happens in Task 6.
- [ ] **Step 8: Commit** `feat: sketchybar bar and widgets`.

---

### Task 6: Schedule, bootstrap wiring, README

**Files:**
- Create: `launchd/com.user.rosepine.plist`
- Modify: `bootstrap.sh`, `README.md`
- Test: `theme/tests/test_plist.sh`

**Interfaces:**
- Consumes: `rosepine-switch` installed at `~/.local/bin/rosepine-switch` by Stow.
- Produces: label `com.user.rosepine`, loaded from `~/Library/LaunchAgents/`.

- [ ] **Step 1: Failing test.** `test_plist.sh` runs `plutil -lint launchd/com.user.rosepine.plist` and asserts the file contains `RunAtLoad`, and `StartCalendarInterval` entries for hour 7 and hour 19. Run it. Expected: FAIL (file missing).
- [ ] **Step 2: Write the plist.** `ProgramArguments` = `[/bin/bash, -lc, "$HOME/.local/bin/rosepine-switch auto"]` (use the literal expanded path via a `__HOME__` placeholder that `bootstrap.sh` substitutes), `RunAtLoad` true, `StartCalendarInterval` array with `{Hour=7,Minute=0}` and `{Hour=19,Minute=0}`, stdout and stderr to `~/.local/state/rose-pine/switch.log`.
- [ ] **Step 3: Run test, expect PASS** (the placeholder must not break `plutil -lint`).
- [ ] **Step 4: Extend `bootstrap.sh`.** After Stow: substitute `__HOME__` and copy the plist to `~/Library/LaunchAgents/`, `launchctl bootout gui/$(id -u)/com.user.rosepine 2>/dev/null || true`, then `launchctl bootstrap gui/$(id -u) <plist>`. Run `rosepine-switch auto`. Start `brew services start sketchybar` and `open -a AeroSpace`. Print a reminder to run `gh auth login` and to grant the System Events Automation prompt and AeroSpace's Accessibility permission.
- [ ] **Step 5: README.** One screen: what is installed, how to run `bootstrap.sh`, how to force a mode (`rosepine-switch dawn|main`), how to change the switch hours (edit the plist and `mode_for_hour`), and the permissions list.
- [ ] **Step 6: Verify on the machine.** Run `bash bootstrap.sh`. Expected: stow conflicts abort cleanly if present, otherwise exit 0. Then `launchctl print gui/$(id -u)/com.user.rosepine` shows the job. Run `rosepine-switch dawn` then `rosepine-switch main` and confirm by eye that the Ghostty, tmux, Starship, SketchyBar, border and system appearance all flip together. Record the result in the task report.
- [ ] **Step 7: Commit** `feat: launchd schedule, bootstrap wiring, readme`.

---

## Self-Review notes

- Spec coverage: SIP-on (Global Constraints, no yabai anywhere), AeroSpace+borders (T4), Rosé Pine main/Dawn (T2 palettes), fixed-time schedule (T2 `mode_for_hour`, T6 plist), system appearance flip (T2 reload), Ghostty/tmux/Starship (T3), bar and all widgets (T5), Stow+Brewfile+bootstrap (T1, T6). Launcher and wallpaper are intentionally absent.
- Interface names used across tasks: `rosepine-switch`, `render_colors_sh|render_tmux|render_starship`, `mode_for_hour`, `colors.sh` with `RP_*`, event `aerospace_workspace_change`. All are defined where produced.
- Review Focus coverage: item 1 → T2 step 2 (hour tests) and the plist's `RunAtLoad`; item 2 → T2 step 6 and 7; item 3 → T2 step 6; item 4 → T1 step 4; item 5 → T5 step 6.
- Known unverifiable-by-test: the visual look and macOS permission prompts. These are manual checks in T3 step 6 and T6 step 6.
