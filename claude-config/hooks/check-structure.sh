#!/usr/bin/env bash
# check-structure.sh — surface ~/.claude structure drift.
#
# The repo uses a FAIL-CLOSED allowlist (.gitignore + .stignore): anything not
# explicitly re-included is silently ignored (not tracked, not synced). That's
# safe, but silent — if Claude Code adds a NEW top-level file/dir, or one moves,
# you'd never know it isn't syncing. This compares the current top-level entries
# of the config dir against a tracked baseline (.structure-manifest) and surfaces
# any additions/removals so you can DECIDE:
#   • TRACK/SYNC it: add `!/<name>` (and `!/<name>/**` for a dir) to BOTH
#     ~/.claude/.gitignore and ~/.claude/.stignore, commit, then re-run --accept.
#   • Acknowledge as intentionally local-only: just run --accept.
#
# Modes:
#   (no args)  HOOK mode — emit SessionStart JSON on drift, silent otherwise; exit 0
#   --report   human-readable report; exit 0 if clean, 3 if drift (manual / CI)
#   --accept   rewrite the manifest to the current top-level state
set -uo pipefail

DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MANIFEST="$DIR/.structure-manifest"
mode="${1:-}"

[ -d "$DIR" ] || exit 0

# Current top-level entries, minus VCS / Syncthing markers / the manifest itself.
list_current() {
  ls -A1 "$DIR" 2>/dev/null \
    | grep -vxE '\.git|\.stfolder|\.stversions|\.structure-manifest|\.DS_Store' \
    | LC_ALL=C sort
}

if [ "$mode" = "--accept" ]; then
  list_current > "$MANIFEST"
  echo "manifest updated: $(wc -l < "$MANIFEST" | tr -d ' ') entries -> $MANIFEST"
  exit 0
fi

if [ ! -f "$MANIFEST" ]; then
  [ "$mode" = "--report" ] && echo "no manifest yet — run: $DIR/hooks/check-structure.sh --accept"
  exit 0
fi

current="$(list_current)"
known="$(LC_ALL=C sort "$MANIFEST")"
new="$(comm -23 <(printf '%s\n' "$current") <(printf '%s\n' "$known") | sed '/^$/d')"
gone="$(comm -13 <(printf '%s\n' "$current") <(printf '%s\n' "$known") | sed '/^$/d')"

[ -z "$new" ] && [ -z "$gone" ] && exit 0   # no drift → silent

disp() { [ -n "$(git -C "$DIR" ls-files -- "$1" 2>/dev/null)" ] && echo tracked || echo ignored; }

body=""
if [ -n "$new" ]; then
  body+="NEW top-level entries (not in baseline):"$'\n'
  while IFS= read -r e; do [ -n "$e" ] && body+="  + $e  [$(disp "$e")]"$'\n'; done <<< "$new"
fi
if [ -n "$gone" ]; then
  body+="GONE (baseline entry no longer present — moved/removed?):"$'\n'
  while IFS= read -r e; do [ -n "$e" ] && body+="  - $e"$'\n'; done <<< "$gone"
fi
body+=$'\n'"Decide per NEW entry: (a) TRACK/SYNC — add '!/<name>' (+ '!/<name>/**' for dirs) to ~/.claude/.gitignore and ~/.claude/.stignore, commit, then re-run --accept; or (b) acknowledge as local-only — run: $DIR/hooks/check-structure.sh --accept"

if [ "$mode" = "--report" ]; then
  printf '⚠️  ~/.claude structure drift:\n%s\n' "$body"
  exit 3
fi

# HOOK mode (SessionStart): inject context for Claude + a banner for the user.
ctx="~/.claude structure drift detected — the fail-closed allowlist may be silently ignoring new config, OR a tracked item moved. $body"
jq -n --arg ctx "$ctx" --arg msg "⚠️ ~/.claude has new/moved entries — review whether they should sync (see context)." '{
  hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $ctx },
  systemMessage: $msg
}'
exit 0
