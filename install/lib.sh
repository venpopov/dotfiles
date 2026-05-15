#!/usr/bin/env bash
# Pure helpers for install.sh, factored out so unit tests can source them.
# This file must have NO side effects when sourced — only function definitions.

# Read a package list file. Returns one package per line, skipping blank lines
# and comments (lines whose first non-whitespace char is `#`).
# Returns silently (status 0, no output) if the file doesn't exist OR contains
# only comments/blank lines. `|| true` normalizes grep's exit 1 (no matches)
# to 0 so callers can treat "valid file, empty after filter" as success.
read_pkgs() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -vE '^\s*(#|$)' "$f" || true
}
