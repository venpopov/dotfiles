#!/usr/bin/env bash
#
# bootstrap.sh — set up the git/file side of ~/.claude sync.
#
# Handles Layer 1 (private config repo at ~/.claude) and the local file side of
# Layer 2 (the tracked .stignore arrives via the repo). You still wire up
# Syncthing + the NAS by hand, and Layer 0 (macOS username unification) is
# manual — see README.md.
#
# Usage:
#   ./bootstrap.sh init <git-remote-url>   # FIRST / canonical Mac:
#                                          #   seed the repo from THIS Mac's
#                                          #   existing ~/.claude, push it,
#                                          #   and deploy it back in place.
#   ./bootstrap.sh join <git-remote-url>   # SECOND Mac:
#                                          #   clone the repo into ~/.claude;
#                                          #   leave session state to Syncthing.
#
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCAFFOLD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

# Authored config — tracked in git. Session state / machine-only junk excluded.
AUTHORED=(
  settings.json settings.local.json keybindings.json CLAUDE.md
  commands agents skills hooks rules
)

# Scaffolding this seed provides (copied in first; real config wins over seeds).
SCAFFOLD=( .gitignore .stignore settings.json CLAUDE.md hooks-git .github )

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

check_gitleaks() {
  command -v gitleaks >/dev/null 2>&1 \
    || warn "gitleaks not installed (brew install gitleaks) — the pre-commit guard will refuse to commit until it is."
}

# Ensure cleanupPeriodDays is large (never auto-delete). NEVER 0 — that disables
# transcript writing entirely.
ensure_cleanup_never() {
  local f="$1"
  command -v python3 >/dev/null 2>&1 || { warn "python3 missing; set cleanupPeriodDays manually in $f"; return; }
  python3 - "$f" <<'PY'
import json, os, sys
f = sys.argv[1]
data = {}
if os.path.exists(f):
    try:
        with open(f) as fh: data = json.load(fh)
    except Exception:
        data = {}
if int(data.get("cleanupPeriodDays", 0)) < 36500:
    data["cleanupPeriodDays"] = 999999
    with open(f, "w") as fh:
        json.dump(data, fh, indent=2); fh.write("\n")
    print("set cleanupPeriodDays=999999 in", f)
PY
}

wire_repo() {
  git -C "$CLAUDE_DIR" config core.hooksPath hooks-git
  chmod +x "$CLAUDE_DIR/hooks-git/pre-commit" 2>/dev/null || true
  # Structure-drift detector: make it executable and seed this machine's
  # per-machine baseline (.structure-manifest, gitignored) so the SessionStart
  # hook stays silent until something actually changes.
  chmod +x "$CLAUDE_DIR/hooks/check-structure.sh" 2>/dev/null || true
  "$CLAUDE_DIR/hooks/check-structure.sh" --accept >/dev/null 2>&1 || true
}

cmd_init() {
  local url="${1:?usage: bootstrap.sh init <git-remote-url>}"
  check_gitleaks
  [[ -d "$CLAUDE_DIR" ]] || die "$CLAUDE_DIR does not exist — run Claude Code at least once first."
  [[ -d "$CLAUDE_DIR/.git" ]] && die "$CLAUDE_DIR is already a git repo — nothing to init."

  local bak="$CLAUDE_DIR.bak.$TS"
  log "Backing up $CLAUDE_DIR -> $bak"
  cp -a "$CLAUDE_DIR" "$bak"

  local tmp; tmp="$(mktemp -d)"
  log "Assembling repo in $tmp"
  for f in "${SCAFFOLD[@]}"; do
    [[ -e "$SCAFFOLD_DIR/$f" ]] && cp -a "$SCAFFOLD_DIR/$f" "$tmp/"
  done
  for f in "${AUTHORED[@]}"; do        # real authored config overrides the seeds
    [[ -e "$CLAUDE_DIR/$f" ]] && cp -a "$CLAUDE_DIR/$f" "$tmp/"
  done
  ensure_cleanup_never "$tmp/settings.json"

  log "Creating git repo and pushing to $url"
  git -C "$tmp" init -q
  git -C "$tmp" config core.hooksPath hooks-git
  chmod +x "$tmp/hooks-git/pre-commit" 2>/dev/null || true
  git -C "$tmp" add -A
  git -C "$tmp" commit -qm "Initial ~/.claude config" \
    || die "nothing committed (pre-commit may have blocked a secret — fix and retry)"
  git -C "$tmp" branch -M main
  git -C "$tmp" remote add origin "$url"
  git -C "$tmp" push -u origin main

  log "Deploying repo into $CLAUDE_DIR (session state left in place)"
  rsync -a "$tmp/" "$CLAUDE_DIR/"      # adds .git + tracked files; no --delete
  wire_repo
  rm -rf "$tmp"

  log "Done (canonical Mac)."
  cat <<EOF

Next (manual):
  • Re-auth Claude if prompted (creds live in Keychain/.credentials.json — machine-only).
  • Syncthing: add folder "$CLAUDE_DIR"; add the NAS as a Receive-Encrypted node
    and the other Mac; enable staggered versioning on ALL nodes. Let THIS Mac
    seed the NAS first and wait for "Up to Date" BEFORE running 'join' on Mac 2.
  • Backup kept at: $bak
EOF
}

cmd_join() {
  local url="${1:?usage: bootstrap.sh join <git-remote-url>}"
  check_gitleaks
  if [[ -e "$CLAUDE_DIR" ]]; then
    local bak="$CLAUDE_DIR.bak.$TS"
    log "Backing up $CLAUDE_DIR -> $bak"
    mv "$CLAUDE_DIR" "$bak"
  fi
  log "Cloning $url -> $CLAUDE_DIR"
  git clone -q "$url" "$CLAUDE_DIR"
  wire_repo

  log "Done (second Mac)."
  cat <<EOF

Next (manual) — ORDER MATTERS:
  • Re-auth Claude (creds are machine-only, in the backup).
  • Syncthing: add folder "$CLAUDE_DIR" + the NAS + the other Mac, then let
    Syncthing PULL projects/ + history.jsonl DOWN from the NAS FIRST
    (wait "Up to Date").
  • Only AFTER that, if you want this Mac's old transcripts too:
       rsync -a "$CLAUDE_DIR.bak.$TS/projects/" "$CLAUDE_DIR/projects/"
    (different session UUIDs merge without overwrite). Never rsync into a folder
    Syncthing is actively two-way syncing.
EOF
}

main() {
  local mode="${1:-}"; shift 2>/dev/null || true
  case "$mode" in
    init) cmd_init "$@" ;;
    join) cmd_join "$@" ;;
    *) die "usage: bootstrap.sh {init|join} <git-remote-url>" ;;
  esac
}
main "$@"
