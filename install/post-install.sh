#!/usr/bin/env bash
# Darwin-only post-bootstrap setup: Touch ID for sudo, MAS apps, file
# associations, Xcode license accept. Idempotent — re-runnable safely.
#
# Gates anything that requires App Store / Apple ID auth on the env var
# BOOTSTRAP_SKIP_AUTH=1, set by CI to keep the workflow non-interactive.
# Real-machine users leave it unset.
#
# Called by `install.sh --bootstrap` after stow + symlinks land.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "post-install: skip (not Darwin)"
  exit 0
fi

SKIP_AUTH="${BOOTSTRAP_SKIP_AUTH:-0}"

# ─── Touch ID for sudo ──────────────────────────────────────────────────────
# /etc/pam.d/sudo_local persists across macOS updates (introduced in Sonoma).
# Idempotent: only append if not already configured.
if grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
  echo "==> Touch ID for sudo already enabled"
else
  echo "==> Enabling Touch ID for sudo"
  echo "auth sufficient pam_tid.so" | sudo tee -a /etc/pam.d/sudo_local >/dev/null
fi

# ─── Mac App Store apps (App Store auth required) ────────────────────────────
if [[ "$SKIP_AUTH" == "1" ]]; then
  echo "==> BOOTSTRAP_SKIP_AUTH=1 — skipping mas installs + Xcode license"
elif ! command -v mas >/dev/null 2>&1; then
  echo "==> mas not installed (Brewfile didn't run?) — skipping MAS apps"
else
  # Format: "<numeric-id>:<human name>"
  mas_apps=(
    "462054704:Microsoft Word"
    "462062816:Microsoft PowerPoint"
    "462058435:Microsoft Excel"
    "1113153706:Microsoft Teams"
    "497799835:Xcode"
  )
  for entry in "${mas_apps[@]}"; do
    id="${entry%%:*}"
    name="${entry#*:}"
    if mas list 2>/dev/null | awk '{print $1}' | grep -qx "$id"; then
      echo "    already installed: $name ($id)"
    else
      echo "==> mas install: $name ($id)"
      mas install "$id" || \
        echo "    FAILED — ensure you're signed into the App Store"
    fi
  done

  # Accept the Xcode license once Xcode itself is installed.
  if command -v xcodebuild >/dev/null 2>&1; then
    if ! xcodebuild -license check >/dev/null 2>&1; then
      echo "==> Accepting Xcode license"
      sudo xcodebuild -license accept
    fi
  fi
fi

# ─── File associations via duti ─────────────────────────────────────────────
# Setting VS Code as the default for code-ish file types. Pasted from the
# explicit list at the bottom of the new-mac checklist; the dynamic linguist
# fetch is deliberately omitted (security: would pin to a SHA, brittleness:
# external dependency at install time).
if ! command -v duti >/dev/null 2>&1; then
  echo "==> duti not installed (Brewfile didn't run?) — skipping file associations"
else
  echo "==> Setting VS Code as default for common file types"
  vscode_types=(
    public.plain-text
    public.source-code
    public.data
    .css .gitattributes .gitignore .htaccess
    .js .json .link .md .scss .sh
    .txt .xml .yaml .yml
    .rmd .qmd .zsh
  )
  for t in "${vscode_types[@]}"; do
    duti -s com.microsoft.VSCode "$t" all 2>/dev/null || true
  done
fi

echo "==> post-install complete"
