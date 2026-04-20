# Dotfiles audit — macbook report

> **Purpose.** Findings and recommendations from the macbook side, tagged for
> merge with a parallel macstudio report. Report only — no code changes made.
>
> **Merge tags** (unchanged from the original draft):
>
> - `[UNIVERSAL]` — true regardless of host; lift directly into merged plan.
> - `[MAC-LOCAL]` — observed here; macstudio sibling must confirm.
> - `[CROSS-CHECK]` — depends on what the sibling reports.
> - `[LINUX-RELEVANT]` — matters mainly for the cloud-server profile.

## Executive summary

`~/dotfiles` has two concrete pains the user flagged:

1. **Slow shell startup + repeated 1Password prompts** (issue #2). Reproduces.
   ~3–7 s cold, dominated by an unconditional `Rscript` call (~1.5 s) and two
   `op read` calls (~1–2 s combined).
2. **Drift across machines.** Live proof right now: this macbook's
   `main` is **5 commits behind `origin/main`** (three rstudio/vscode tweaks
   plus the `minimalist-zsh` PR merge). Nothing tells the user this on
   shell startup.

Repo layout (Stow + XDG per `CLAUDE.md`) is correct and stays. No migration
to chezmoi/yadm/nix-darwin proposed.

Grounded recommendations below, prioritized by impact-to-effort. Most are
`[UNIVERSAL]`; sections explicitly tagged `[LINUX-RELEVANT]` or `[CROSS-CHECK]`
need the sibling report or a Linux container to act on.

---

## Draft corrections — what the original draft got wrong

The incoming draft overstated some of the mess. Verified against **the actual
macbook tree** (not a clone):

| Draft claim | Reality on macbook | Verdict |
|---|---|---|
| 9 committed `.DS_Store` files | 9 `.DS_Store` files exist **on disk** but **zero are tracked** (`git/.gitignore_global` already ignores them globally) | **Draft overstated.** Nothing to `git rm --cached`. Adding repo-level `.gitignore` globs is still worthwhile belt-and-suspenders. |
| `.zsh_history` (301 KB) tracked | File exists on disk at 301 KB but is **not tracked**. Already gitignored. | **Draft overstated.** |
| Stowing runtime files would clobber each machine | `.zcompdump` (49 KB) and `.zsh_sessions/_expiration_check_timestamp` (0 B) **ARE** tracked | **Draft correct.** Real issue. |
| Empty `prompts/` package | Exists. Zero files inside. | **Draft correct.** |
| Stale README (`.dotfiles` vs `dotfiles`) | Confirmed. 14 lines, wrong clone path. | **Draft correct.** |
| Hardcoded `/Users/venpopov/.ghcup/env` at `.zshrc:31` | Confirmed. Violates CLAUDE.md "use `$HOME`" rule. | **Draft correct.** |
| Nested git repo at `nvim/.config/nvim/.git` | Confirmed — it's `venpopov/kickstart-modular.nvim`, a fork of `dam9000/kickstart-modular.nvim` with an `upstream` remote and one uncommitted mod to `lua/kickstart/plugins/lspconfig.lua`. | **Draft correct.** Additional fact: upstream tracking makes this *deliberate*, not accidental. |
| Empty `~/.zshrc` at `$HOME` | Confirmed — 0 bytes. | **Draft correct.** |
| `zsh/.zprofile` — brew shellenv | Path is actually `zsh/.config/zsh/.zprofile` (not the repo's top-level `zsh/`). Still a single unconditional `/opt/homebrew/bin/brew` line. | **Draft mislabeled path** but problem is real. |
| Root `.gitignore` specificity | Contains four hardcoded `.zsh_sessions` UUID paths — brittle. | **Draft correct.** |

All other draft findings (cmdstan slow path, eager `op`/`gh` exports, dead
`zinit`, commented p10k, macOS-only `gpg.ssh.program` in `.gitconfig`) reproduce
cleanly in the tree.

---

## Findings (macbook-verified)

### 1. Repo state `[UNIVERSAL]`

| Item | Location | Observation |
|---|---|---|
| Tracked runtime files | `zsh/.config/zsh/.zcompdump`, `zsh/.config/zsh/.zsh_sessions/_expiration_check_timestamp` | Already in `zsh/.config/zsh/.gitignore`, but **tracked** — local ignore only applies to untracked files. `stow -R zsh` on a new machine would symlink these over the machine's own compdump. |
| Brittle root `.gitignore` | `.gitignore` | Hardcoded UUIDs (e.g. `22E18652-C539-4C2C-AC34-E5C17C2C95E9.history`). New sessions on new machines produce different UUIDs, so the ignore won't catch them. |
| `.DS_Store` on disk | 9 files (`1Password/`, `gh/`, `gh/.config/`, `nvim/`, `nvim/.config/`, `ssh/`, `zsh/`, `zsh/.config/`, repo root) | Untracked thanks to `~/.gitignore_global` linked via `git/.gitignore_global`. No code action needed, but visible every `git status`. |
| Empty `prompts/` package | `prompts/` | `stow prompts` is a no-op. Either populate or remove from package list. |
| Stale README | `README.md` | 14 lines, wrong clone path (`.dotfiles`), no prereqs, no platform notes. |
| Hardcoded user path | `zsh/.config/zsh/.zshrc:31` | `[ -f "/Users/venpopov/.ghcup/env" ]` — violates the "use `$HOME`" rule. Cosmetic here (username matches), structurally wrong. |
| Empty `~/.zshrc` | `$HOME` (not repo) | 0-byte legacy artifact from before `ZDOTDIR` was set. Zsh reads `~/.config/zsh/.zshrc`. Harmless but confusing. |
| Dead-code dotfiles | `~/.bashrc` (envman + juliaup + cargo), `~/.profile` (cargo + ghcup) | Not sourced by zsh. Their PATH exports are duplicated by `exports.zsh` + `add_to_path`. |

### 2. Shell startup tax (issue #2) `[UNIVERSAL]` (the perf shape) / `[MAC-LOCAL]` (the specific secret backends)

Every new interactive zsh runs these blocking subprocesses, in order:

| Source | Call | Cost | Notes |
|---|---|---|---|
| `exports.zsh:14` | `Rscript --vanilla -e 'cat(cmdstanr::cmdstan_path())'` | **0.8–2.0 s** | R cold-start. Single biggest offender. Path basically never changes. |
| `exports.zsh:35` | `op read 'op://dev/VADE library bearer/password'` | 0.5–2 s cold, 0.2–0.6 s warm | 1Password biometric / agent prompt. |
| `exports.zsh:36` | `op read 'op://dev/vade-app.dev/password'` | same | Sequential with the previous. |
| `exports.zsh:37` | `gh auth token` | 0.2–0.4 s | `gh` CLI spin-up. |
| `exports.zsh:34` | `security find-generic-password -s mem0-vade-coo -w` | 0.05–0.15 s | macOS keychain. Errors on Linux. |
| `.zshrc:26` | `source <(fzf --zsh)` | 0.2–0.4 s | Standard fzf integration. |
| `.zshrc:8–10` | Zinit bootstrap + `source zinit.zsh` | ~0.1 s | **No `zinit ice`/`zinit load` anywhere** — plugin manager is sourced but loads nothing. |
| `.zshrc:13–17` | Powerlevel10k block — **commented out** | 0 | So the prompt is plain zsh default. `p10k/.p10k.zsh` (95 KB of tuning) is stowed but inert. |

**Estimated cold total**: 3–7 s. **Warm**: 1.5–3 s. **Target after fixes**:
warm under 0.7 s.

The `claude()` wrapper at `functions.zsh:40` already demonstrates the
lazy-secret pattern — that's the template to mirror for the other two
1Password calls.

### 3. Cross-machine sync gaps `[UNIVERSAL]`

- **No bootstrap script.** README is 14 lines. A fresh machine needs brew,
  stow, zinit (auto-clones on first zsh), fzf, bat, gh, op, nvim, R +
  cmdstanr — none documented.
- **No `Brewfile`.** Reproducing the macOS toolchain is guesswork.
- **No drift detection.** Nothing tells the user `~/dotfiles` is behind
  `origin/main`. p10k's vcs segment (if it were on) shows status of the
  *current* dir, not dotfiles.
- **Nested nvim repo is *deliberate*** but undocumented. It's a fork of
  kickstart-modular.nvim with `upstream` tracking and local customization
  (currently one modified `lua/kickstart/plugins/lspconfig.lua`). Needs either:
  (a) its own entry in `dotfiles-pull`, or (b) vendoring (drop upstream
  remote, commit customizations to the parent repo). Option (b) is simpler
  but loses the ability to cherry-pick kickstart updates — the user should
  pick.
- **Live proof of drift.** At the moment of this audit, macbook is
  **5 commits behind `origin/main`** — `5f4400c` (merge PR #1), `af6e915`
  (merge main into minimalist-zsh), `7045c3d` (copilot merge + conflict
  resolve), `5ae1c84` (add zsh to vscode terminal), `8d33b18` (rstudio
  prefs tweak). None conflict with anything in this report, but the user
  should pull before acting.

### 4. Linux/cloud-server gaps `[LINUX-RELEVANT]`

- `zsh/.config/zsh/.zprofile` hardcodes `/opt/homebrew/bin/brew` —
  Linuxbrew is at `/home/linuxbrew/.linuxbrew/bin/brew`.
- `exports.zsh`'s `Linux)` branch is empty: no `SSH_AUTH_SOCK`, no fallback
  for secrets that assume `op` + `security` + macOS biometrics exist.
- `git/.gitconfig:7` — `gpg.ssh.program = /Applications/1Password.app/...` is
  macOS-only. Every Linux commit would fail if `commit.gpgsign` were on;
  `commit.gpgsign = false` is what's saving it today.
- macOS-only stow packages (`1Password/`, `rstudio/`, `p10k/`) symlink inert
  files on Linux — harmless but noisy; `bootstrap.sh` should skip them.

### 5. Untracked `~/.config/` inventory (macbook) `[CROSS-CHECK]`

Full inventory of `~/.config/` on macbook. Cross-reference against the
macstudio sibling's inventory — the **intersection** is the safe set to
start tracking.

| Dir | Likely worth tracking? | Notes |
|---|---|---|
| `marimo/` | Probably yes | Cross-platform notebook tool. |
| `uv/` | Probably yes | Python package manager; small text config. |
| `rclone/` | Maybe | May contain credentials — needs inspection before tracking. |
| `ghc/` | Maybe | Haskell; only if used on multiple machines. |
| `coq/` | Unknown | Cross-check with macstudio. |
| `crossnote/` | Unknown | Cross-check with macstudio. |
| `envman/` | Unknown | Auto-generated by envman; probably per-machine state. |
| `zotero-mcp/` | Unknown | Cross-check with macstudio. |
| `github-copilot/` | No | Auth state, per-machine. |
| `keyboardcowboy/` | No | macOS-only GUI tool. |
| `raycast/` | No | macOS-only, large, mostly state. |
| `qBittorrent/` | No | Per-machine. |
| `op/` | No | 1Password CLI per-account state. |

Top-level in `$HOME` worth a call:

- `~/.bashrc` — auto-generated by envman/juliaup/cargo. **Not sourced by zsh**,
  so its exports are dead code unless you `bash` explicitly. Options: delete,
  port the exports into `exports.zsh`, or source it from `.zshenv` (order
  matters). Low priority but trivial.
- `~/.profile` (103 B) — cargo + ghcup. Same dead-code story.
- `~/.claude/` — `settings.json`, `CLAUDE.md`, commands, agents, skills. **High-
  value cross-check candidate.** If both machines have hand-written Claude
  commands, they should be synced.

---

## Recommendations (prioritized)

Tagged + grouped by concern. Each item is a proposal, not a commitment; the
merged plan picks from this list.

### A. Cleanup pass `[UNIVERSAL]` — small, safe, do first

1. Replace root `.gitignore`'s UUID-specific lines with globs:
   ```
   zsh/.config/zsh/.zsh_history*
   zsh/.config/zsh/.zsh_sessions/
   zsh/.config/zsh/.zcompdump*
   **/.DS_Store
   **/._.DS_Store
   ```
2. `git rm --cached` the two tracked runtime files (they stay on disk):
   - `zsh/.config/zsh/.zcompdump`
   - `zsh/.config/zsh/.zsh_sessions/_expiration_check_timestamp`
3. Decide `prompts/`: either populate (e.g. stow target for
   `~/.config/claude/` prompts) or delete the package. If deleting, also
   remove from `CLAUDE.md:11`'s package inventory.
4. Rewrite `README.md`: correct clone path, per-platform prereqs, one-line
   `stow */`, pointer to `CLAUDE.md` for architecture and (eventually)
   `bootstrap.sh` for automation.
5. `.zshrc:31` — replace `/Users/venpopov/...` with `${HOME}/...`.
6. On the host (not in repo): delete the empty `~/.zshrc` after confirming
   `ZDOTDIR` is honored. `env | grep ZDOTDIR` before touching.

**Not doing** (draft suggested; inapplicable):
- `git rm --cached` on `.DS_Store` — none tracked.
- `git rm --cached .zsh_history` — not tracked.

### B. Shell startup speedup `[UNIVERSAL]`

Order by impact, highest first. Benchmark gate:
`for i in {1..5}; do time zsh -i -c exit; done` before/after each step.

1. **Cache the cmdstan path.** Replace `exports.zsh:14` with a cache read;
   add a `refresh_cmdstan_path` helper in `functions.zsh`. ~1.5 s saved.
   ```zsh
   # functions.zsh
   refresh_cmdstan_path() {
     local cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/cmdstan_path"
     mkdir -p "${cache:h}"
     command -v Rscript >/dev/null || { echo "Rscript not found" >&2; return 1; }
     Rscript --vanilla -e 'cat(cmdstanr::cmdstan_path())' > "$cache"
   }

   # exports.zsh — replaces the unconditional Rscript call
   _cmdstan_cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/cmdstan_path"
   [[ -s $_cmdstan_cache ]] && add_to_path "$(<"$_cmdstan_cache")/bin"
   ```
2. **Lazy 1Password secrets.** Mirror `claude()` at `functions.zsh:40`. Drop
   `LIBRARY_BEARER` and `VADE_AUTH_TOKEN` exports; add:
   ```zsh
   library_bearer()  { op read 'op://dev/VADE library bearer/password'; }
   vade_auth_token() { op read 'op://dev/vade-app.dev/password'; }
   ```
   Audit consumers (`grep -r LIBRARY_BEARER ~/GitHub` and similar) and update
   them to call the function or use `op run --env-file=...`. ~1–2 s saved,
   biometric prompt moves to the caller.
3. **Replace `gh auth token` with the `op` gh plugin** (`op plugin init gh`,
   run once per machine during bootstrap). Remove `GH_TOKEN` export. ~0.3 s
   saved. `[CROSS-CHECK]`: confirm macstudio also uses gh.
4. **Guard `security` so Linux doesn't error.** Wrap `exports.zsh:34` in
   `command -v security >/dev/null`.
5. **Decide zinit + p10k** — they currently cost ~0.1 s for nothing. Two
   options:
   - **Minimal**: delete the zinit block (`.zshrc:7-10`) and the `p10k/`
     stow package.
   - **Restore**: uncomment the p10k instant-prompt block at `.zshrc:13-17`,
     add `zinit light romkatv/powerlevel10k` plus the usual trio
     (`zsh-users/zsh-syntax-highlighting`, `zsh-users/zsh-autosuggestions`,
     `zsh-users/zsh-completions`).

   Recommendation: **Restore** — `.p10k.zsh` is 95 KB of tuning worth keeping.
   Fall back to Minimal only if the benchmark regresses past the 0.7 s target.

### C. Multi-machine bootstrap & drift `[UNIVERSAL]`

1. **`Brewfile`** at repo root. Seed with `brew bundle dump --describe` on
   macbook, trim to the actually-used set (stow, fzf, bat, gh, neovim, jq,
   1password-cli, ripgrep, r, radian, node, etc.).
2. **`bootstrap.sh`** at repo root — bash, idempotent, platform-dispatching:
   - Detect `uname -s`.
   - Darwin: install brew if missing → `brew bundle --file=Brewfile` →
     `op plugin init gh` (no-op if done).
   - Linux: print apt/yum install list (don't auto-install; server policies
     vary).
   - Both: `stow */` from repo root, filtering out macOS-only packages on
     Linux (`1Password/`, `rstudio/`, `p10k/`).
   - Print one-line status per package: `stowed` / `skipped` / `conflict`.
   - Second run: exits 0, no-op.
3. **`dotfiles-status` function** wired into `precmd_functions`:
   - Fetch `origin` at most once per 6 h (timestamp guard at
     `${XDG_CACHE_HOME}/dotfiles/last_fetch`).
   - Print `dotfiles: ahead=N behind=M dirty` only when non-zero.
   - Gate on `[[ -d ${HOME}/dotfiles/.git ]]` so it no-ops on cloud servers
     with a different clone path.
4. **`dotfiles-pull` helper**. Two versions depending on the nested-nvim
   decision:
   - Keep fork: `dotfiles-pull() { git -C ~/dotfiles pull --ff-only && git -C ~/dotfiles/nvim/.config/nvim pull --ff-only origin; }`
   - Vendor: `dotfiles-pull() { git -C ~/dotfiles pull --ff-only; }`
5. **Decide the nvim fork fate.** Currently
   `venpopov/kickstart-modular.nvim` with `upstream`. The macbook copy has an
   uncommitted modification to `lua/kickstart/plugins/lspconfig.lua`.
   Options:
   - **Keep**: commit the local mod upstream-ward, document in CLAUDE.md,
     add to `dotfiles-pull`.
   - **Vendor**: drop the `.git` dir and upstream remote, commit files to the
     parent repo, lose the cherry-pick-from-kickstart affordance.

   Recommendation: **Keep and document** — the cherry-pick affordance is
   the point of a fork. `[CROSS-CHECK]`: confirm the macstudio nvim HEAD
   (ask sibling for `git -C ~/dotfiles/nvim/.config/nvim rev-parse HEAD` —
   macbook is at `c5b8da6`).

### D. Cross-platform robustness `[LINUX-RELEVANT]`

1. Make `.zprofile` Linux-aware:
   ```sh
   case "$(uname -s)" in
     Darwin)
       [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
       ;;
     Linux)
       [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
       ;;
   esac
   ```
2. Move `[gpg "ssh"]` out of the tracked `.gitconfig`. Replace with:
   ```gitconfig
   [includeIf "gitdir:~/"]
     path = ~/.config/git/config.local
   ```
   and commit a template `git/.config/git/config.local.macos` containing
   the `op-ssh-sign` path, stowed into place only on macOS by `bootstrap.sh`.
   Linux just doesn't have the file; git ignores the missing include.
   Keep `commit.gpgsign = false` as the tracked default.
3. Codify a "cloud server" profile: the subset of packages that apply on
   Linux (`zsh git nvim gh ssh`). Skip `1Password/`, `rstudio/`, `p10k/`.
   `bootstrap.sh` enforces this mechanically.

### E. Track more configs `[CROSS-CHECK]`

Decide once both reports are in. Likely-yes: `~/.config/uv/`,
`~/.config/marimo/`, parts of `~/.claude/` (commands, agents, settings
minus machine-specific). Likely-no: `~/.config/raycast/`,
`~/.config/keyboardcowboy/`, `~/.config/op/`, `~/.config/github-copilot/`,
`~/.config/qBittorrent/`. Hold the rest until the macstudio inventory lands.

---

## What the macstudio sibling needs to report (for clean merge)

1. **`ls ~/.config/`** inventory, with the same per-dir verdict column.
2. **Startup tax** reproduction: `time zsh -i -c exit` 5×, report median.
3. Whether the macstudio also has commented-out p10k or a different prompt
   (maybe they actually restored p10k already).
4. Whether `~/.bashrc`, `~/.profile`, `~/.zshrc` exist and have non-trivial
   content — if the macstudio's match macbook's, we can fold them into
   `exports.zsh` once and delete them from both.
5. Nested nvim repo HEAD: `git -C ~/dotfiles/nvim/.config/nvim rev-parse HEAD`
   (macbook is at `c5b8da6`, with uncommitted `lspconfig.lua` change).
   Whether the macstudio has its own uncommitted changes there.
6. Which tools from this macbook's "untracked candidates" (`marimo`, `uv`,
   `rclone`, `ghc`, `coq`, `crossnote`, `envman`, `zotero-mcp`) also exist
   on the macstudio — the intersection is the safe track set.
7. Any configs the macstudio uses that the macbook doesn't — those become
   `[STUDIO-LOCAL]` in the merged plan.
8. Whether macstudio is also behind `origin/main`, and by how much — tells
   us whether drift is symmetric or one-sided.

---

## Critical files (macbook paths, for the merged implementation plan)

- `zsh/.config/zsh/.zshrc` — line 31 (hardcoded path); lines 7–17 (zinit +
  commented p10k decision); line 26 (fzf).
- `zsh/.config/zsh/exports.zsh` — line 14 (cmdstan); lines 34–37 (secrets).
  Primary perf surface.
- `zsh/.config/zsh/functions.zsh` — `FUNCTIONS_ZSH_LOADED` sentinel, `claude()`
  template (line 40) for lazy secrets; gets `refresh_cmdstan_path`, lazy
  secret fns, `dotfiles-status`, `dotfiles-pull`.
- `zsh/.config/zsh/.zprofile` — single-line brew shellenv; needs Linux branch.
- `git/.gitconfig` — line 7 (macOS-only `op-ssh-sign`).
- `.gitignore` (root) — replace UUID lines with globs.
- `stow/.stow-global-ignore` — already excludes `.DS_Store`; no change.
- `CLAUDE.md` — update package list after zinit/p10k and prompts decisions.
- `README.md` — full rewrite.
- `nvim/.config/nvim/` — nested fork repo (HEAD `c5b8da6`, with uncommitted
  `lua/kickstart/plugins/lspconfig.lua`); decision pending.
- **New**: `Brewfile`, `bootstrap.sh`, `git/.config/git/config.local.macos`.

---

## Verification plan (post-merge implementation)

1. **Startup time.** `for i in {1..5}; do time zsh -i -c exit; done` before
   and after Phase B. Warm median ≤ 0.7 s.
2. **Cold 1Password.** `op signout && time zsh -i -c exit` — must stay fast;
   then call `library_bearer` and confirm the prompt fires only there.
3. **Bootstrap idempotency.** `bash bootstrap.sh && bash bootstrap.sh` on a
   freshly-cloned repo (or Linux Docker) — second run exits 0 with no-op.
4. **Drift detection.** `git -C ~/dotfiles reset --soft HEAD~1`, open a new
   shell — precmd prints `behind=1`. `git reset HEAD@{1}` to undo.
5. **Stow re-apply.** `stow -n -v */` dry-run from repo root — zero conflicts,
   no orphan symlinks for the now-untracked runtime files.
6. **Linux fallback.** Ubuntu container, run bootstrap subset — no hangs on
   missing `op` / `security` / `gh`, PATH contains linuxbrew and
   `~/.local/bin`.

---

## Pre-implementation housekeeping

Before applying any merged plan, on this macbook:

- `git -C ~/dotfiles pull --ff-only` — pulls the 5 commits currently on
  `origin/main` (vscode terminal tweak, rstudio prefs, minimalist-zsh PR
  merge). None of them conflict with anything in this report.
- On the macstudio side: have the sibling do the same before its audit,
  so both reports measure the same baseline.
