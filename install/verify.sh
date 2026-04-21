#!/usr/bin/env bash
# Post-stow sanity check. Exits non-zero if expected symlinks are missing.
set -u
fail=0
check_symlink() {
  local link="$1"
  if [[ ! -L "$link" ]]; then
    echo "MISSING SYMLINK: $link" >&2
    fail=1
  fi
}
check_exists() {
  # For files inside stowed directories — parent dir is the symlink, not the file.
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "MISSING: $path" >&2
    fail=1
  fi
}
check_symlink "$HOME/.zshenv"
check_symlink "$HOME/.config/zsh"
check_exists  "$HOME/.config/zsh/.zshrc"
check_exists  "$HOME/.config/zsh/exports.zsh"
check_exists  "$HOME/.config/zsh/functions.zsh"
check_symlink "$HOME/.gitconfig"
check_symlink "$HOME/.gitignore_global"
# .ssh/config: stow may fold (on fresh Linux where ~/.ssh didn't exist, stow
# links the whole .ssh dir) or unfold (on macOS where ~/.ssh held real keys,
# each file is its own symlink). Either way the file is reachable; check -e.
check_exists  "$HOME/.ssh/config"
exit $fail
