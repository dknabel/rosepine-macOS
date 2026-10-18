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
