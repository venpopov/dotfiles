#!/usr/bin/env bash
# Install apt packages required by the dotfiles on Linux.
# Called by `bash install.sh --bootstrap` on Linux. Idempotent (apt-get install
# is naturally so).
#
# Stage 3 scope: just the packages listed in install/apt.pkgs. Stage 5 will
# add 1Password CLI (op), optional linuxbrew, and any non-apt bits surfaced
# by the UZH SciCloud setup.
#
# Usage: bash install/linux-deps.sh [--dry-run]
set -euo pipefail

DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  '') ;;
  *) echo "unknown arg: $1" >&2; exit 2 ;;
esac

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=install/lib.sh
source "$REPO_DIR/install/lib.sh"

mapfile -t pkgs < <(read_pkgs "$REPO_DIR/install/apt.pkgs")

if (( ${#pkgs[@]} == 0 )); then
  echo "no apt packages listed in install/apt.pkgs"
  exit 0
fi

if [[ "$DRY" -eq 1 ]]; then
  echo "(dry-run) sudo apt-get install ${pkgs[*]}"
  exit 0
fi

echo "==> sudo apt-get install: ${pkgs[*]}"
sudo apt-get update
sudo apt-get install -y --no-install-recommends "${pkgs[@]}"
