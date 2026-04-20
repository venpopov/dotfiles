# Dotfiles workflow overhaul — Mac Studio side

**Machine:** `PSY-KOMPMOD-C01.local` (Mac Studio, macOS 26.4.1, arm64)
**Local user:** `vepopo` · **Git user:** Ven Popov (`venpopov` on GitHub)
**Repo state at audit:** `main`, clean, up-to-date with origin
**Date:** 2026-04-20

## Context

The dotfiles repo at `~/.dotfiles` has accumulated cruft over time and is used across three environments: MacBook (laptop), Mac Studio (office — this machine), and ephemeral Linux servers. The user wants to smooth the cross-machine workflow. Two concrete pain points motivate the overhaul:

1. **GitHub issue #2** — new zsh shells take "several seconds" to start and 1Password repeatedly prompts for auth on new terminals.
2. **Drift** — changes on one machine don't get pushed/pulled promptly, leading to silent divergence.

This file is the **Mac Studio half** of a diagnostic that will be merged with a parallel analysis produced on the MacBook. It is intentionally **not** an execution-ready plan — it captures what this machine sees, proposes a direction, and flags decisions to resolve during the merge. A later session will write the actual staged execution plan once both sides are on the table.

User decisions already captured:
- **Secrets: lazy**, *except* that `git`/`gh` must always work without manual activation. Never block an interactive git/gh operation on an unprimed token.
- **Stale packages:** retire `p10k/`, keep `rstudio/`.
- **Scope:** diagnostic + proposed direction now; execution plan later.

---

## Mac Studio findings (concrete, with file:line)

### Broken on this machine right now

| # | Location | Issue |
|---|---|---|
| B1 | `zsh/.config/zsh/.zshrc:31` | Sources `/Users/venpopov/.ghcup/env` — hardcoded path with wrong local username (`venpopov` vs. `vepopo`). Dead source on both Macs. Should be `$HOME/.ghcup/env`. |
| B2 | `zsh/.config/zsh/exports.zsh:15` | Single-quoted `$HOME` in OPAM init path — variable never expands. Source silently no-ops. |
| B3 | `zsh/.config/zsh/exports.zsh:14` | Unguarded `Rscript --vanilla -e 'cat(cmdstanr::cmdstan_path())'` on every shell startup. Spawns an R process per terminal (major contributor to issue #2); breaks on machines without R/cmdstanr. |
| B4 | `1Password/.config/.DS_Store`, `1Password/.config/1Password/.DS_Store` | macOS metadata committed to repo. Will sync to Linux boxes as noise. `stow/.stow-global-ignore` already excludes future ones; these two slipped in before that was added. |

### Fragile (will fail or prompt on some machine state)

| # | Location | Issue |
|---|---|---|
| F1 | `zsh/.config/zsh/exports.zsh:34-37` | `op read` calls at startup: synchronous 1Password round-trips. If vault is locked, prompt per shell. Primary cause of issue #2's "repeated auth requests." |
| F2 | `zsh/.config/zsh/functions.zsh:41` | `claude()` wrapper calls `op read` inline every invocation — correct pattern, but hardcodes vault item `vade-coo-mcp-2026-04` which looks like it rotates monthly. |
| F3 | `zsh/.config/zsh/functions.zsh:32` | `destroy_github_repo()` invokes `Rscript` unguarded. Fails on any machine without R. |
| F4 | `ssh/.ssh/config:2` | `IdentityAgent` points at `~/Library/Group Containers/.../agent.sock` globally — correct for macOS, **will break ssh on Linux** when the same config is stowed there. |

### Cruft / inconsistent

| # | Location | Issue |
|---|---|---|
| C1 | `p10k/` package + `zshrc:13-17` | Powerlevel10k sourcing fully commented out but the package still exists. User decided: **retire p10k** (delete package + dead block). |
| C2 | `rstudio/` | 4 files, macOS-GUI-only. Keep, but gate to Darwin in any machine-aware manifest. |
| C3 | `README.md` | Install instructions are 4 lines: clone, install stow, cd, stow. No dependency story, no Brewfile, no guidance on which packages to stow where. Ephemeral-server use-case is undocumented. |

### Deployment gaps on Mac Studio specifically

| # | Location | Issue |
|---|---|---|
| D1 | `~/.config/nvim` | **Does not exist** on Mac Studio — not a symlink, not a directory. The `nvim/` package (~35 files, Kickstart-based) is fully specced in the repo but dormant here. Unclear if this is intentional or oversight. Flagged for follow-up. |
| D2 | `~/.profile` | 35-byte untracked regular file in `$HOME`. Contents unknown; not read during the audit. Needs a glance to decide: adopt, delete, or ignore. |
| D3 | Bootstrap | No `install.sh`, no Brewfile, no dependency check, no platform-aware stow driver. Fresh-machine setup is manual and error-prone. |

### Untracked-but-maybe-interesting

| # | Location | Note |
|---|---|---|
| U1 | `~/.config/raycast/` | 37 extensions + config. High value if syncable, but Raycast may not tolerate a symlinked config dir — needs a 5-minute test before committing. |
| U2 | `~/.config/crossnote/` | Markdown editor customization (`config.js`, `style.less`, `parser.js`, `head.html`). Decide after MacBook confirms whether it's installed there. |

### Git hygiene

- `git/.gitignore_global` covers `.DS_Store`, `.env`, R/Rproj/quarto artifacts. Reasonable.
- Per-package `.gitignore` files correctly exclude `.zsh_history`, `.zsh_sessions`, `.zcompdump`, `lazy-lock.json`.
- No secrets tracked.
- The two `1Password/.../.DS_Store` files noted in B4 are the only cleanup items.

---

## Proposed direction (for merge with MacBook side)

Five themes. Each is a direction, not an execution list — execution sizing happens after the merge.

### Theme 1 · Hot-fix the broken bits (Stage 0)

Unambiguous bugs with zero design surface. Can ship the day the merged plan lands, on both Macs, with no cross-machine coordination:

- Fix `zshrc:31` hardcoded `/Users/venpopov/` → `$HOME`
- Fix `exports.zsh:15` single-quoted `$HOME`
- Guard `Rscript` calls at `exports.zsh:14` and `functions.zsh:32` with `command -v Rscript`
- Delete the two tracked `.DS_Store` files in `1Password/`
- Retire `p10k/` package + the commented-out block at `.zshrc:13-17`

Expected impact: measurable shell-startup speedup from item #3 alone (no more R subprocess per terminal).

### Theme 2 · Startup perf + secret timing (issue #2)

**User decision:** secrets lazy, but `git`/`gh` always available without manual activation. That means:

- `GH_TOKEN` via `gh auth token` → **eager** (no network, no prompt; cheap). Guard with `command -v gh`.
- SSH via 1Password agent (`SSH_AUTH_SOCK`) → **eager** on Darwin (already effectively free; no per-shell prompt because the agent is an app-level daemon). Must remain Darwin-only (see F4).
- `op read` calls (`LIBRARY_BEARER`, `VADE_AUTH_TOKEN`) → **lazy**. Move to a `secrets.zsh` helper with a `with_op` wrapper function, or prefer `op run --env-file=...` at command invocation for tools that need env vars at exec time. Zero startup prompts.
- `MEM0_API_KEY` (Keychain) → **eager** (Keychain on an unlocked login session is prompt-free).
- cmdstan PATH → cache computed value to `~/.cache/zsh/cmdstan_path`, source the cache at startup, expose `refresh_cmdstan_path` function to recompute manually.

Result target: `time zsh -i -c exit` sub-300ms on Mac Studio; zero 1Password prompts until the user runs `claude` or a `vade-*` command.

**Coordinate with MacBook side before implementing** — the MacBook analysis may reveal different consumers of these env vars that force an adjustment to which ones stay eager.

### Theme 3 · Machine-aware stow driver (new `install.sh`)

Add a top-level `install.sh` + `install/` manifest directory. Keep 1-package-per-tool layout (don't fold into groups). Manifests:

- `install/common.pkgs` — `zsh`, `git`, `gh`, `nvim`, `stow`, `ssh`
- `install/darwin.pkgs` — adds `1Password`, `rstudio`, `R`, `lintr`
- `install/linux.pkgs` — common only
- `install/host.<hostname>.pkgs` — optional override per machine

`install.sh` flags: `--bootstrap` (first-time), default (re-stow), `--dry-run`, `--minimal` (ephemeral Linux). Idempotent. Calls `install/verify.sh` at the end to check every expected symlink.

Add `install/Brewfile` (curated minimum, not `brew bundle dump`): `stow`, `gh`, `neovim`, `fzf`, `bat`, `ripgrep`, `zsh`, cask `1password`, cask `1password-cli`, cask `rstudio`, `radian`, `quarto`. Mirror a Linux `install/apt.pkgs`.

**SSH config split:** wrap the macOS-only `IdentityAgent` line in `~/.dotfiles/ssh/.ssh/config` in a `Match exec "uname -s | grep -q Darwin"` block so one file works on both platforms. Avoids per-platform package split.

### Theme 4 · Sync hygiene (drift prevention)

Lightest-touch option only:

- `dotfiles-sync.zsh` sourced from `.zshrc`. On interactive shell startup, once per session, background-`git fetch` `~/.dotfiles` if last fetch > 4h old. Inspect `git status` + ahead/behind. If dirty or behind, print one line: `dotfiles: N modified, M behind — run 'dotsync'`.
- `dotsync` function: `(cd ~/.dotfiles && git pull --rebase && git status)`.
- `dotpush` function: `(cd ~/.dotfiles && git add -A && git commit -m "${1:-sync}" && git push)`.

Reject autopush cron (silent config commits = footgun). Reject prompt badge (couples to theme, noisy).

### Theme 5 · Staged rollout order

After the merge, land in this order, one commit/PR per stage, Mac Studio first, MacBook second, ephemeral Linux last:

- **Stage 0** — hot fixes (Theme 1). Same-day. No behavior change to design.
- **Stage 1** — bootstrap infra (Theme 3 without Theme 2). Additive; no existing behavior changes.
- **Stage 2** — machine-aware manifests + SSH config `Match` block. Test re-stow on Mac Studio (expect no-op), throwaway Linux VM with `--minimal`.
- **Stage 3** — startup perf + secret timing (Theme 2). Most likely to surface breakage because it changes *when* env vars populate. Validate with `hyperfine 'zsh -i -c exit'` before/after.
- **Stage 4** — sync hygiene (Theme 4). Low risk; defer until above is stable.

---

## Critical files this touches

- `~/.dotfiles/zsh/.config/zsh/.zshrc` — hot fixes, p10k block removal, sync hook
- `~/.dotfiles/zsh/.config/zsh/exports.zsh` — secrets timing, cmdstan cache, bug fixes
- `~/.dotfiles/zsh/.config/zsh/functions.zsh` — `with_op` helper, guards, `dotsync`/`dotpush`
- `~/.dotfiles/zsh/.config/zsh/secrets.zsh` — *new*, lazy secret wrappers
- `~/.dotfiles/zsh/.config/zsh/dotfiles-sync.zsh` — *new*, drift detector
- `~/.dotfiles/ssh/.ssh/config` — `Match` block for Darwin-only `IdentityAgent`
- `~/.dotfiles/install.sh` — *new*, bootstrap + stow driver
- `~/.dotfiles/install/{common,darwin,linux}.pkgs`, `install/Brewfile`, `install/apt.pkgs`, `install/verify.sh` — *new*
- `~/.dotfiles/p10k/` — delete after merge
- `~/.dotfiles/1Password/.config/.DS_Store` (×2) — delete
- `~/.dotfiles/README.md` — rewrite with bootstrap story

## Open questions to resolve in the merge

The MacBook-side agent won't know these either; they're for the merge session:

1. **nvim on Mac Studio.** `~/.config/nvim` doesn't exist here. Oversight or intentional? Determines whether Mac Studio's host manifest excludes nvim.
2. **rstudio drift.** Is `~/.dotfiles/rstudio/` the source of truth, or has the local RStudio app diverged on either Mac? Matters because re-stowing will clobber.
3. **`claude()` wrapper rotation.** `functions.zsh:41` hardcodes vault item `vade-coo-mcp-2026-04`. Monthly rotation would mean every rotation is a dotfiles commit — config knob instead?
4. **ephemeral Linux access pattern.** How often, from where, behind firewalls ever? If always clean cloud images, the `curl | bash --minimal` path is fine; otherwise need offline bundle.
5. **Brewfile scope.** Curated minimum (my recommendation) or full `brew bundle dump` snapshot? Could do both — curated as `Brewfile`, full as `Brewfile.full` for DR.
6. **raycast / crossnote adoption.** Worth tracking? Depends on whether MacBook uses both, neither, or the same.
7. **`~/.profile` disposition.** 35-byte file on Mac Studio, untracked. Adopt / delete / ignore.
8. **Linux `1password-cli`.** If secrets go fully lazy and `op` isn't installed on Linux, the lazy wrappers must no-op gracefully. Confirm acceptable behavior (error with a clear message vs. silent skip).

## Verification approach (for the eventual execution plan)

End-to-end checks to include in the later execution plan, before and after each stage:

- `time zsh -i -c exit` on both Macs (target: <300ms after Stage 3)
- `hyperfine -w 3 'zsh -i -c exit'` for a stable number
- `ssh -T git@github.com` on Mac and Linux (SSH via 1Password agent / fallback)
- `gh auth status && gh repo view` without priming (validates eager GH_TOKEN)
- `git push` on a dummy commit in a throwaway repo (validates SSH path)
- Fresh Docker/Linux VM: `curl | bash --bootstrap --minimal` → working zsh + nvim + git in under 2 minutes
- `stow -n -v --target=$HOME --restow <each-pkg>` to confirm idempotence after Stage 1
- Re-stowing on a machine where a tracked file has been locally mutated: verify `install/verify.sh` catches it rather than silently skipping
