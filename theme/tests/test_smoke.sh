#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash -n "$root/bootstrap.sh"
echo "ok: bootstrap.sh syntax"
