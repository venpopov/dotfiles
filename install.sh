#!/usr/bin/env bash
# Bootstrap + idempotent re-stow driver.
# Usage:
#   bash install.sh [--bootstrap] [--dry-run] [--minimal]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

BOOTSTRAP=0
DRY=0
MINIMAL=0
for arg in "$@"; do
  case "$arg" in
    --bootstrap) BOOTSTRAP=1 ;;
    --dry-run)   DRY=1 ;;
    --minimal)   MINIMAL=1 ;;
    -h|--help)
      sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

os="$(uname -s)"

# Pure helpers (read_pkgs, etc.) live in install/lib.sh so unit tests can
# source them without running the full driver.
# shellcheck source=install/lib.sh
source "$REPO_DIR/install/lib.sh"

pkgs=()
while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/common.pkgs)
if [[ "$MINIMAL" -eq 0 ]]; then
  case "$os" in
    Darwin) while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/darwin.pkgs) ;;
    Linux)  while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/linux.pkgs) ;;
  esac
fi

if [[ "$BOOTSTRAP" -eq 1 ]]; then
  case "$os" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        echo "install brew first: https://brew.sh" >&2; exit 1
      fi
      echo "==> brew bundle"
      if [[ "$DRY" -eq 1 ]]; then
        echo "(dry-run)"
      else
        brew bundle --file=install/Brewfile
      fi
      ;;
    Linux)
      if [[ "$DRY" -eq 1 ]]; then
        bash install/linux-deps.sh --dry-run
      else
        bash install/linux-deps.sh
      fi
      ;;
  esac
fi

stow_flag=""
[[ "$DRY" -eq 1 ]] && stow_flag="-n"

for pkg in "${pkgs[@]}"; do
  if [[ -d "$pkg" ]]; then
    echo "==> stow $pkg"
    # --ignore catches .DS_Store even before ~/.stow-global-ignore is in place
    # (stow/.stow-global-ignore only takes effect after `stow stow` runs).
    stow $stow_flag --ignore='\.DS_Store' -v --target="$HOME" --restow "$pkg"
  else
    echo "skip: $pkg (not present)"
  fi
done

# macOS-only git local include: point ~/.config/git/config.local at the
# darwin-specific fragment (gpg-ssh program = 1Password op-ssh-sign).
# Linux silently ignores the missing include path — no-op there.
if [[ "$os" == "Darwin" && "$DRY" -eq 0 ]]; then
  mkdir -p "$HOME/.config/git"
  if [[ ! -e "$HOME/.config/git/config.local" ]]; then
    ln -s "$REPO_DIR/git/.config/git/config.local.darwin" \
          "$HOME/.config/git/config.local"
    echo "==> linked ~/.config/git/config.local -> config.local.darwin"
  fi
fi

# macOS-only: ~/Downloads -> iCloud Drive Downloads, so the Mac shares its
# Downloads folder with iOS/iPadOS. May halt on first run if TCC blocks the
# rmdir — follow the script's printed instructions and re-run.
if [[ "$os" == "Darwin" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    bash install/icloud-downloads.sh --dry-run
  else
    bash install/icloud-downloads.sh
  fi
fi

bash install/verify.sh
