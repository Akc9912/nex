#!/usr/bin/env bash
# Update the nex environment: pull latest changes, re-render, re-link, verify.
set -euo pipefail
ROOT="${NEX_ROOT:-$HOME/nex}"
cd "$ROOT"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git pull --ff-only || true
fi
node "$ROOT/scripts/render.mjs"
bash "$ROOT/scripts/link.sh"
bash "$ROOT/scripts/verify.sh"
echo "nex update: done"
