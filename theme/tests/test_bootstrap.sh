#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Regression: sourcing runs nothing (no output, no side effects).
out="$(HOME="$tmp/h0" bash -c "source '$root/bootstrap.sh'" 2>&1)" || fail "source failed: $out"
[ -z "$out" ] || fail "sourcing produced output: $out"
[ ! -e "$tmp/h0" ] || fail "sourcing touched HOME"

export HOME="$tmp/home"; mkdir -p "$HOME"
stub="$tmp/launchctl"
printf '#!/bin/sh\necho "$@" >> "%s/calls"\n' "$tmp" > "$stub"; chmod +x "$stub"
export LAUNCHCTL="$stub"
source "$root/bootstrap.sh"

# zshrc hook
printf 'export FOO=bar\n' > "$HOME/.zshrc"
install_zshrc_hook; install_zshrc_hook
[ "$(grep -c '^# >>> rose-pine rice >>>$' "$HOME/.zshrc")" = 1 ] || fail "start marker count"
[ "$(grep -c '^# <<< rose-pine rice <<<$' "$HOME/.zshrc")" = 1 ] || fail "end marker count"
grep -q '^export FOO=bar$' "$HOME/.zshrc" || fail "preexisting content lost"
grep -q '\.zshrc\.d/\*\.zsh' "$HOME/.zshrc" || fail "no source loop"
rm "$HOME/.zshrc"; install_zshrc_hook
[ -f "$HOME/.zshrc" ] || fail "zshrc not created"

# launchd agent
install_launchd_agent
pl="$HOME/Library/LaunchAgents/com.user.rosepine.plist"
[ -f "$pl" ] || fail "plist not written"
! grep -q __HOME__ "$pl" || fail "__HOME__ left"
grep -q "$HOME/.local/bin/rosepine-switch" "$pl" || fail "HOME path missing"
plutil -lint "$pl" >/dev/null || fail "installed plist lint"
grep -q '^bootstrap ' "$tmp/calls" || fail "launchctl bootstrap not called"
[ -d "$HOME/.local/state/rose-pine" ] || fail "state dir missing"
echo "ok test_bootstrap"

# HOME with special characters: plist stays valid and command is quoted exact path.
for name in "sp ace" "am&p" 'pi|pe' 'back\slash'; do
  export HOME="$tmp/$name"; mkdir -p "$HOME"
  install_launchd_agent
  pl="$HOME/Library/LaunchAgents/com.user.rosepine.plist"
  plutil -lint "$pl" >/dev/null || fail "lint failed for HOME '$name'"
  cmd="$(plutil -extract ProgramArguments.2 raw "$pl")"
  [ "$cmd" = "\"$HOME/.local/bin/rosepine-switch\" tick" ] || fail "command wrong for '$name': $cmd"
  [ "$(plutil -extract StandardOutPath raw "$pl")" = "$HOME/.local/state/rose-pine/switch.log" ] || fail "logpath '$name'"
done

# launchctl bootstrap failure: warn, return 0 even under set -e, retry once.
export HOME="$tmp/failhome"; mkdir -p "$HOME"
bad="$tmp/badlaunchctl"
printf '#!/bin/sh\necho "$@" >> "%s/badcalls"\n[ "$1" = bootstrap ] && exit 5\nexit 0\n' "$tmp" > "$bad"; chmod +x "$bad"
err="$(LAUNCHCTL="$bad" LAUNCHD_RETRY_SLEEP=0 bash -ec "source '$root/bootstrap.sh'; install_launchd_agent; echo reached" 2>&1 >"$tmp/stdout")" || fail "function returned nonzero"
grep -q reached "$tmp/stdout" || fail "later steps did not run"
echo "$err" | grep -q 'warn: launchctl bootstrap failed' || fail "no warning: $err"
echo "$err" | grep -q 'launchctl bootstrap gui/' || fail "no retry command"
[ "$(grep -c '^bootstrap ' "$tmp/badcalls")" = 2 ] || fail "expected one retry"
echo "ok test_bootstrap failure/escaping"

# Static: patsub_replacement must be disabled before the first escape (bash 5.2 makes & special).
fn="$(sed -n '/^install_launchd_agent()/,/^}/p' "$root/bootstrap.sh")"
shopt_line="$(echo "$fn" | grep -n 'shopt -u patsub_replacement' | head -1 | cut -d: -f1)"
esc_line="$(echo "$fn" | grep -n 'esc="\${esc//' | head -1 | cut -d: -f1)"
[ -n "$shopt_line" ] && [ -n "$esc_line" ] && [ "$shopt_line" -lt "$esc_line" ] || fail "shopt must precede escapes"
echo "ok test_bootstrap shopt order"
