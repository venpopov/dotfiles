# claude-config — seed for a synced `~/.claude`

Seed for syncing Claude Code's `~/.claude` across two interchangeable Macs.
Copy the **contents** of this directory into a fresh **private** GitHub repo
(e.g. `venpopov/claude-config`) — `bootstrap.sh init` does this for you.

> Full design + rationale: **venpopov/dotfiles#22**. This is **not** a stow
> package — don't `stow` it.

## The three layers

| Layer | What | How |
|---|---|---|
| **0** | Unify the macOS username so transcript paths match | manual (see below) |
| **1** | Version-control *authored* config | a **private** git repo cloned at `~/.claude` |
| **2** | Sync *auto-written* session state | Syncthing, with the NAS as an always-on **encrypted** node |

What's tracked in git vs synced by Syncthing vs left machine-only:

- **git (this repo):** `settings.json`, `settings.local.json`, `keybindings.json`,
  `commands/`, `agents/`, `skills/`, `hooks/`, `rules/`, `CLAUDE.md`, `.stignore`.
- **Syncthing → NAS (encrypted):** `projects/` (transcripts), `history.jsonl`.
- **Machine-only (never synced):** `.credentials.json` + Keychain, `~/.claude.json`,
  and volatile caches (`statsig/`, `ide/`, `session-env/`, `shell-snapshots/`,
  `file-history/`, `plans/`, `debug/`, `plugins/`).

## Prerequisites (both Macs)

```sh
brew install gitleaks            # required: the pre-commit guard refuses to commit without it
brew install --cask syncthing-app
```
Syncthing on the NAS too (Synology/QNAP package or Docker; TrueNAS app).

## Layer 0 — unify the username (do first, on the non-canonical Mac)

Needed only for cross-machine `--resume` (transcripts are keyed by absolute
path). Recommended route — **fresh account + migrate** (old account stays
bootable = rollback):

1. New admin account with the canonical short name → `/Users/<canonical>`.
2. `sudo rsync -avHE /Users/<old>/ /Users/<canonical>/ && sudo chown -R <canonical> /Users/<canonical>`
3. Before retiring the old account: re-sign 1Password (+ SSH agent: `ssh -T`,
   `op` work), iCloud; re-auth `claude` and `gh`; make the new account a
   FileVault unlock user and confirm boot-unlock; re-add Login Items.
4. Audit for hardcoded `/Users/<old>` and replace with `$HOME`/`$XDG_*`.
5. Verify, then delete the old account ("save home folder as a disk image").

## Layer 1 — the config repo

**Canonical Mac** (whose `~/.claude` seeds the repo). Create an empty **private**
repo on GitHub, then:

```sh
./bootstrap.sh init git@github.com:venpopov/claude-config.git
```

This backs up `~/.claude`, assembles the repo from this seed + your real authored
config, ensures `cleanupPeriodDays` is large (never auto-delete), pushes, and
deploys the repo back in place at `~/.claude` (your session state is left
untouched).

**Second Mac** (after the NAS has the canonical Mac's state — see Layer 2):

```sh
./bootstrap.sh join git@github.com:venpopov/claude-config.git
```

### Day-to-day
Authored edits are normal files in `~/.claude`:
```sh
git -C ~/.claude add -A && git -C ~/.claude commit -m "..." && git -C ~/.claude push
git -C ~/.claude pull        # on the other Mac
```
No auto-pull is wired into the `claude` shell wrapper on purpose — Claude
auto-writes `settings.json` (model/effort/fast-mode), which would abort a
`pull --rebase`. Those writes just show as diffs you commit when you sync.

## Layer 2 — Syncthing + the NAS

1. On **each Mac and the NAS**, add the folder `~/.claude` to Syncthing.
2. Make the **NAS a "Receive Encrypted" node** (set a folder password) so
   transcripts/history are encrypted at rest on the hub; both Macs hold
   plaintext. (A Receive-Encrypted node can't act as an introducer — connect
   the two Macs directly to each other and to the NAS.)
3. Enable **staggered file versioning on all three nodes** — with never-delete
   in effect, this is your retention/safety backstop.
4. The tracked `.stignore` (allowlist) limits the synced set to `projects/` +
   `history.jsonl`; it ships with the repo, so it's present after clone.

**Bring-up order (avoids a conflict storm):** canonical Mac seeds the NAS first
→ wait "Up to Date" → then `join` the second Mac and let it **pull from the NAS
first** → only then optionally copy that Mac's historical transcripts in.

**Concurrency:** don't drive the *same* live session on both Macs at once — it
can create a recoverable `.sync-conflict-*` copy. (Conservative alternative: a
`Stop` hook that snapshots only completed transcripts.)

## Verify

```sh
ls -la ~/.claude                                   # real files, not symlinks
git -C ~/.claude check-ignore projects history.jsonl .credentials.json .stfolder .stversions
git -C ~/.claude ls-files | grep -E 'settings.json|CLAUDE.md|.stignore'   # tracked
python3 -c 'import json;print(json.load(open("'$HOME'/.claude/settings.json"))["cleanupPeriodDays"])'  # large, not 0
# pre-commit guard blocks secrets — stage a throwaway file containing a fake
# AWS-key-shaped token (the literal string "AKIA" + 16 uppercase/digit chars)
# and confirm the commit is refused:
printf 'AKIA%s\n' 'IOSFODNN7EXAMPLE' > ~/.claude/leaktest \
  && git -C ~/.claude add leaktest && git -C ~/.claude commit -m x ; rm -f ~/.claude/leaktest
```
Then: start a session on Mac A, let Syncthing sync, and on Mac B
`claude --resume` should both **list** it (history.jsonl synced) and resume the
transcript.

## Notes
- `.gitignore` is a **fail-closed allowlist** (`/*` then `!/name` re-includes).
  To start tracking a NEW authored item, add a `!/name` line. To make something
  genuinely machine-specific, just drop its `!` line (e.g. `settings.local.json`,
  which is tracked by default under "nothing machine-only").
- Secrets never go in any settings file — keep them in 1Password / the shell
  wrappers; gitleaks enforces this.
