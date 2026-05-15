#!/usr/bin/env bash
# Install Linux dependencies for the dotfiles. Called by install.sh
# --bootstrap on Linux. Idempotent — apt-get install is naturally so;
# the 1Password apt-repo + bat-symlink steps are guarded by feature checks.
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

# ─── apt packages from install/apt.pkgs ─────────────────────────────────────
mapfile -t pkgs < <(read_pkgs "$REPO_DIR/install/apt.pkgs")
if (( ${#pkgs[@]} == 0 )); then
  echo "no apt packages listed in install/apt.pkgs"
else
  if [[ "$DRY" -eq 1 ]]; then
    echo "(dry-run) sudo apt-get install ${pkgs[*]}"
  else
    echo "==> sudo apt-get install: ${pkgs[*]}"
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends "${pkgs[@]}"
  fi
fi

# ─── 1Password CLI (op) ─────────────────────────────────────────────────────
# Only on amd64 — 1Password's apt repo is amd64-only. ARM users will need
# the snap (not scripted here). Idempotent: skip if already installed.
if command -v op >/dev/null 2>&1; then
  echo "==> op already installed: $(op --version)"
elif [[ "$DRY" -eq 1 ]]; then
  echo "(dry-run) install 1Password CLI via apt"
else
  arch="$(dpkg --print-architecture 2>/dev/null || echo unknown)"
  if [[ "$arch" != "amd64" ]]; then
    echo "==> Skipping op install: only amd64 supported via apt (arch: $arch)"
  else
    echo "==> Installing 1Password CLI (op)"
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
      sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | \
      sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y 1password-cli
  fi
fi

# ─── bat → batcat shim ──────────────────────────────────────────────────────
# Ubuntu/Debian install the `bat` binary as `batcat` to avoid a namespace
# clash with another (unrelated) `bat` package. The user's `exports.zsh`
# checks for `bat` specifically; without this shim, the bat manpager + alias
# silently skip on Linux. ~/.local/bin is in PATH via add_to_path in
# exports.zsh, so the symlink is visible from interactive shells.
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "(dry-run) ln -s \$(command -v batcat) \$HOME/.local/bin/bat"
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "==> Linked ~/.local/bin/bat -> $(command -v batcat)"
  fi
fi
