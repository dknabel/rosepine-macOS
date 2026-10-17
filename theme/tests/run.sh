#!/usr/bin/env bash
# Run every test_*.sh in this directory; exit non-zero on the first failure.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for t in "$dir"/test_*.sh; do
  [ -e "$t" ] || continue
  echo "== $(basename "$t")"
  bash "$t" || { echo "FAIL: $(basename "$t")" >&2; exit 1; }
done
echo "All tests passed"
