#!/usr/bin/env bash
# Tests for the SketchyBar plugins, run against stubs on a restricted PATH.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
sb="$root/stow/sketchybar/.config/sketchybar"
plugins="$sb/plugins"
fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

[ -x "$sb/sketchybarrc" ] || fail "sketchybarrc missing or not executable"
for p in workspaces front_app clock battery wifi volume media github; do
  [ -x "$plugins/$p.sh" ] || fail "plugin $p.sh missing or not executable"
  [ -f "$sb/items/$p.sh" ] || fail "item $p.sh missing"
  bash -n "$plugins/$p.sh" || fail "syntax $p.sh"
  bash -n "$sb/items/$p.sh" || fail "syntax items/$p.sh"
done
bash -n "$sb/sketchybarrc" || fail "syntax sketchybarrc"

# Fixture colors (distinct from the real palette) so assertions prove sourcing.
export HOME="$tmp/home"
mkdir -p "$HOME/.local/state/rose-pine"
cat > "$HOME/.local/state/rose-pine/colors.sh" <<'C'
export RP_BASE=0xff000001 RP_SURFACE=0xff000002 RP_OVERLAY=0xff000003
export RP_MUTED=0xff000004 RP_SUBTLE=0xff000005 RP_TEXT=0xff000006
export RP_LOVE=0xff000007 RP_GOLD=0xff000008 RP_ROSE=0xff000009
export RP_PINE=0xff00000a RP_FOAM=0xff00000b RP_IRIS=0xff00000c
C

# Build a PATH holding only core tools plus the stubs for scenario $1.
# Scenarios: missing (no external commands), fail (all fail, print errors),
# nodata (the "nothing to show" outputs), data (healthy outputs).
build_bin() {
  local mode="$1" bin="$tmp/bin.$1" t
  rm -rf "$bin"; mkdir -p "$bin"
  for t in env bash sed grep awk cut tr head tail cat date dirname basename wc sort; do
    ln -s "$(command -v "$t")" "$bin/$t"
  done
  cat > "$bin/sketchybar" <<'S'
#!/bin/sh
for a in "$@"; do printf '%s\n' "$a" >> "$SB_LOG"; done
S
  chmod +x "$bin/sketchybar"
  stub() { # name, body
    printf '#!/bin/sh\n%s\n' "$2" > "$bin/$1"; chmod +x "$bin/$1"
  }
  case "$mode" in
    fail)
      for t in aerospace pmset networksetup ipconfig osascript nowplaying-cli gh; do
        stub "$t" 'echo "command not found: error: boom"; echo "error: boom" >&2; exit 1'
      done ;;
    nodata)
      stub aerospace 'exit 0'
      stub pmset 'echo "Now drawing from '"'"'AC Power'"'"'"'
      stub networksetup 'echo "You are not associated with an AirPort network."'
      stub ipconfig 'exit 0'
      stub osascript 'echo "missing value"'
      stub nowplaying-cli 'echo null; echo null'
      stub gh 'case "$1" in auth) exit 0;; esac; echo 0' ;;
    data)
      stub aerospace 'case "$*" in *"--workspace 2"*) echo Ghostty; echo Safari;; *"--workspace 3"*) echo Mystery;; esac'
      stub pmset 'printf "%s\n" "Now drawing from '"'"'Battery Power'"'"'" " -InternalBattery-0 (id=1)	15%; discharging; 1:00 remaining"'
      stub ipconfig 'echo "    SSID : HomeNet"'
      stub networksetup 'echo "Current Wi-Fi Network: HomeNet"'
      stub osascript 'case "$*" in *muted*) echo false;; *) echo 42;; esac'
      stub nowplaying-cli 'echo "A Very Long Song Title That Goes On And On Forever"; echo "Some Artist"'
      stub gh 'case "$1" in auth) exit 0;; esac; echo 7' ;;
  esac
}
for m in missing fail nodata data; do build_bin "$m"; done

# run <mode> <plugin> [VAR=val ...]; leaves recorded args in $log, sets rc.
run() {
  local mode="$1" plugin="$2"; shift 2
  log="$tmp/log.$mode.$plugin"; : > "$log"
  rc=0
  env -i HOME="$HOME" PATH="$tmp/bin.$mode" SB_LOG="$log" SKETCHYBAR_EXTRA_PATH=/nonexistent NAME="$plugin" "$@" \
    bash "$plugins/$plugin.sh" >"$tmp/out" 2>"$tmp/err" || rc=$?
}
has() { grep -qF -- "$1" "$log" || { echo "log was:"; cat "$log"; fail "expected '$1' ($CASE)"; }; }
hasnt() { ! grep -qF -- "$1" "$log" || { echo "log was:"; cat "$log"; fail "unexpected '$1' ($CASE)"; }; }

# 1. Every plugin exits 0 in every scenario; no error strings reach the bar.
for m in missing fail nodata data; do
  for p in workspaces front_app clock battery wifi volume media github; do
    CASE="$m/$p"
    nm="$p"; [ "$p" = workspaces ] && nm=workspace.2
    run "$m" "$p" NAME="$nm" FOCUSED_WORKSPACE=2 INFO="Safari" SENDER=forced
    [ "$rc" = 0 ] || { cat "$tmp/err" >&2; fail "$CASE exited $rc"; }
    if grep -qiE 'command not found|error' "$log"; then cat "$log"; fail "$CASE passed error text to sketchybar"; fi
  done
done

# 2. Battery.
CASE=battery-nodata; run nodata battery;  has "drawing=off"
CASE=battery-missing; run missing battery; has "drawing=off"
CASE=battery-fail;    run fail battery;    has "drawing=off"
CASE=battery-nobatt-msg
run nodata battery  # pmset says nothing about a battery
has "drawing=off"
CASE=battery-low; run data battery
has "drawing=on"; has "15%"; has "icon.color=0xff000007"; hasnt "0xff00000b"

# 3. Media.
CASE=media-null;    run nodata media;  has "drawing=off"
CASE=media-missing; run missing media; has "drawing=off"
CASE=media-fail;    run fail media;    has "drawing=off"
CASE=media-data;    run data media
has "drawing=on"; has "Some Artist - "; has "label.color=0xff000008"
# truncated to 30 chars max
lbl="$(grep -m1 '^label=' "$log")"; lbl="${lbl#label=}"
[ "${#lbl}" -gt 0 ] && [ "${#lbl}" -le 30 ] || fail "media label not 1..30 chars: '$lbl'"

# 4. GitHub.
CASE=gh-zero;    run nodata github;  has "drawing=off"
CASE=gh-missing; run missing github; has "drawing=off"
CASE=gh-fail;    run fail github;    has "drawing=off"
CASE=gh-data;    run data github;    has "drawing=on"; has "7"; has "0xff00000a"

# 5. Wifi, volume, clock, front_app produce sane output.
CASE=wifi-data; run data wifi; has "HomeNet"; has "icon.color=0xff00000c"
CASE=wifi-down; run nodata wifi; hasnt "HomeNet"; has "icon.color="
CASE=volume-data; run data volume; has "42"; has "icon.color=0xff000009"
CASE=clock; run data clock; has "label="
CASE=front_app; run data front_app INFO="Safari" SENDER=front_app_switched; has "Safari"

# 6. Workspaces: focused gets IRIS, others OVERLAY; empty unfocused hidden.
CASE=ws-focused;   run data workspaces NAME=workspace.2 FOCUSED_WORKSPACE=2
has "background.color=0xff00000c"; hasnt "background.color=0xff000003"; has "drawing=on"
CASE=ws-unfocused; run data workspaces NAME=workspace.2 FOCUSED_WORKSPACE=5
has "background.color=0xff000003"; hasnt "background.color=0xff00000c"; has "drawing=on"
CASE=ws-icons; has ":ghostty:"; has ":safari:"
CASE=ws-unknown; run data workspaces NAME=workspace.3 FOCUSED_WORKSPACE=5; has ":default:"
CASE=ws-empty-hidden; run data workspaces NAME=workspace.7 FOCUSED_WORKSPACE=5; has "drawing=off"
CASE=ws-empty-focused; run data workspaces NAME=workspace.7 FOCUSED_WORKSPACE=7
has "drawing=on"; has "background.color=0xff00000c"

CASE=ws-sender-fallback
cp "$tmp/bin.data/aerospace" "$tmp/aerospace.orig"
printf '#!/bin/sh\ncase "$*" in *"--focused"*) echo 5;; *"--workspace 2"*) echo Ghostty;; esac\n' > "$tmp/bin.data/aerospace"
run data workspaces NAME=workspace.5 SENDER=front_app_switched
has "background.color=0xff00000c"
run data workspaces NAME=workspace.2 SENDER=space_windows_change
has "background.color=0xff000003"; hasnt "background.color=0xff00000c"
cp "$tmp/aerospace.orig" "$tmp/bin.data/aerospace"
for ev in aerospace_workspace_change front_app_switched space_windows_change; do
  grep -qE -- "--subscribe .*$ev" "$sb/items/workspaces.sh" || fail "workspaces item not subscribed to $ev"
done
! grep -q -- '--add event.*space_windows_change' "$sb"/sketchybarrc "$sb"/items/*.sh || fail "built-in event re-registered"

# 7. sketchybarrc sources colors, has fallback block, and references all items.
grep -q 'colors.sh' "$sb/sketchybarrc" || fail "sketchybarrc does not source colors.sh"
grep -q 'aerospace_workspace_change' "$sb/sketchybarrc" || fail "event not registered"
for p in workspaces front_app clock battery wifi volume media github; do
  grep -q "items/$p.sh" "$sb/sketchybarrc" || grep -q 'items/\*\.sh\|items/' "$sb/sketchybarrc" || fail "items not sourced"
done

# 8. PATH: sketchybarrc and env.sh export Homebrew dirs; every plugin sources env.sh.
want='export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"'
grep -qF "$want" "$sb/sketchybarrc" || fail "sketchybarrc lacks PATH export"
grep -q 'export PATH=.*/opt/homebrew/bin:/usr/local/bin' "$plugins/env.sh" || fail "env.sh lacks PATH export"
for p in workspaces front_app clock battery wifi volume media github; do
  grep -qF '. "${0%/*}/env.sh"' "$plugins/$p.sh" || fail "$p.sh does not source env.sh"
done
# Behavioral: a command living only in the extra PATH dir is found.
extra="$tmp/extra"; mkdir -p "$extra"
printf '#!/bin/sh\necho Ghostty\n' > "$extra/aerospace"; chmod +x "$extra/aerospace"
CASE=path-extra; log="$tmp/log.path"; : > "$log"
env -i HOME="$HOME" PATH="$tmp/bin.missing" SB_LOG="$log" SKETCHYBAR_EXTRA_PATH="$extra" \
  NAME=workspace.4 FOCUSED_WORKSPACE=1 bash "$plugins/workspaces.sh" || fail "path-extra exit"
has ":ghostty:"

# 9. Item order: explicit, right side clock, battery, wifi, volume.
order="$(grep -E '^for name in ' "$sb/sketchybarrc")"
[ "$order" = "for name in workspaces front_app media clock battery wifi volume github; do" ] \
  || fail "item order wrong: $order"
! grep -q 'items/\*' "$sb/sketchybarrc" || fail "alphabetical glob still used"

echo "sketchybar plugins ok"
