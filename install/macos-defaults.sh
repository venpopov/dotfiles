#!/usr/bin/env bash
# Darwin-only `defaults write` settings, seeded from the new-mac checklist.
# Expand here as the VM trial surfaces more preferences worth scripting.
#
# `defaults write` is idempotent — repeated calls with the same value are
# no-ops. Re-running the whole script is safe.
#
# Usage: bash install/macos-defaults.sh [--dry-run]
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macos-defaults: skip (not Darwin)"
  exit 0
fi

DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  '') ;;
  *) echo "unknown arg: $1" >&2; exit 2 ;;
esac

run() {
  if [[ "$DRY" -eq 1 ]]; then
    echo "(dry-run) $*"
  else
    "$@"
  fi
}

echo "==> Applying macOS defaults"

# Disable .DS_Store creation on network volumes. From the new-mac checklist.
run defaults write com.apple.desktopservices DSDontWriteNetworkStores true

echo "==> macOS defaults applied"
