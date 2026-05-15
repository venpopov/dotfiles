#!/usr/bin/env bash
# Read-only drift detector. Called by `bash install.sh --doctor`.
# Reports what's out of sync between the repo's expected state and the
# machine's actual state. Exits 0 if everything is in sync, 1 if any
# drift is detected.
#
# Sections (each prints a header and findings):
#   1. Symlinks         — wraps install/verify.sh
#   2. Stow drift       — `stow -n` per package, lists planned LINK actions
#   3. Brewfile / apt   — missing packages (Darwin via `brew bundle check`,
#                         Linux via per-package `dpkg -s`)
#   4. Git sync         — ahead / behind / dirty counts vs upstream
#
# No mutations. No `sudo`. No network beyond a `git fetch` already done by
# `dotfiles-sync.zsh`.
set -uo pipefail   # NOT -e — we want all sections to run even if one fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

# shellcheck source=install/lib.sh
source "$REPO_DIR/install/lib.sh"

os="$(uname -s)"
any_drift=0

# Build the same package list install.sh uses.
pkgs=()
while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/common.pkgs)
case "$os" in
  Darwin) while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/darwin.pkgs) ;;
  Linux)  while IFS= read -r p; do pkgs+=("$p"); done < <(read_pkgs install/linux.pkgs) ;;
esac

# ─── 1. Symlinks ─────────────────────────────────────────────────────────────
echo "=== Symlinks ==="
if bash install/verify.sh >/dev/null 2>&1; then
  echo "  all expected symlinks present"
else
  any_drift=1
  bash install/verify.sh 2>&1 | sed 's/^/  /'
fi

# ─── 2. Stow drift ───────────────────────────────────────────────────────────
echo
echo "=== Stow ==="
for pkg in "${pkgs[@]}"; do
  if [[ ! -d "$pkg" ]]; then
    echo "  $pkg: package directory missing"
    any_drift=1
    continue
  fi
  # `stow -n` shows planned actions without performing them. Empty output =
  # already-stowed.
  drift=$(stow -n -v --ignore='\.DS_Store' --target="$HOME" "$pkg" 2>&1 | \
          grep -E '^(LINK|UNLINK|MKDIR|RMDIR)' || true)
  if [[ -z "$drift" ]]; then
    echo "  $pkg: in sync"
  else
    any_drift=1
    echo "  $pkg: drift"
    printf '    %s\n' "$drift"
  fi
done

# ─── 3. Brewfile / apt ───────────────────────────────────────────────────────
echo
case "$os" in
  Darwin)
    echo "=== Brewfile ==="
    if ! command -v brew >/dev/null 2>&1; then
      echo "  brew not installed (run: bash install.sh --bootstrap)"
      any_drift=1
    elif brew bundle check --file=install/Brewfile >/dev/null 2>&1; then
      echo "  all Brewfile deps satisfied"
    else
      any_drift=1
      echo "  drift:"
      brew bundle check --file=install/Brewfile --verbose 2>&1 | sed 's/^/    /' || true
    fi
    ;;
  Linux)
    echo "=== apt packages ==="
    if ! command -v dpkg >/dev/null 2>&1; then
      echo "  dpkg not found (not Debian-family?) — skipping apt check"
    else
      mapfile -t apt_list < <(read_pkgs install/apt.pkgs)
      missing=()
      for pkg in "${apt_list[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
          missing+=("$pkg")
        fi
      done
      if (( ${#missing[@]} == 0 )); then
        echo "  all apt packages installed"
      else
        any_drift=1
        echo "  missing: ${missing[*]}"
      fi
    fi
    ;;
esac

# ─── 4. Git sync ─────────────────────────────────────────────────────────────
echo
echo "=== Git sync ==="
# `.git` is a directory in normal clones and a file in worktrees, so checking
# the path isn't enough — use git plumbing to confirm we're inside a repo.
if ! git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "  not a git repo — skipping"
else
  ahead=$(git -C "$REPO_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  behind=$(git -C "$REPO_DIR" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
  dirty=$(git -C "$REPO_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if (( ahead + behind + dirty == 0 )); then
    echo "  in sync with origin, working tree clean"
  else
    any_drift=1
    echo "  ahead=$ahead behind=$behind dirty=$dirty — run dotsync / dotpush"
  fi
fi

echo
if (( any_drift == 0 )); then
  echo "==> doctor: all in sync"
  exit 0
else
  echo "==> doctor: drift detected (rerun \`bash install.sh\` to reconcile stow + symlinks; \`bash install.sh --bootstrap\` to install missing brew/apt deps)"
  exit 1
fi
