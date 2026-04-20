# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

Personal dotfiles, deployed to `$HOME` via GNU Stow. There is no build, lint, or test suite — this repo *is* configuration. The same files are used across multiple computers and are meant to be general.

## Layout: Stow packages

Each top-level directory (`zsh/`, `git/`, `nvim/`, `R/`, `gh/`, `ssh/`, `1Password/`, `lintr/`, `p10k/`, `rstudio/`, `stow/`, `prompts/`) is an independent **stow package**. The directory tree inside each package mirrors the layout that will appear under `$HOME` once stowed.

Example: `zsh/.config/zsh/.zshrc` becomes `~/.config/zsh/.zshrc` after `stow zsh` is run from the repo root. This is XDG-compliant — most configs live under `.config/`, not as top-level dotfiles.

Deploy a package:

```
cd ~/dotfiles && stow <package>
```

`stow/.stow-global-ignore` excludes `.DS_Store` from every package.

## Zsh architecture

Zsh is split across multiple files, coordinated by `$ZDOTDIR`:

- `zsh/.zshenv` → `~/.zshenv` (the only file at the default path). Sets XDG vars and **`ZDOTDIR=~/.config/zsh`**. Everything else lives under `ZDOTDIR`.
- `zsh/.config/zsh/.zprofile` — sets up Homebrew env.
- `zsh/.config/zsh/.zshrc` — sources the three modules below, bootstraps Zinit (cloned on first run), wires up fzf and `bat` manpager.
- `zsh/.config/zsh/functions.zsh` — self-guarded with `FUNCTIONS_ZSH_LOADED` sentinel (safe to source twice). Defines `add_to_path`, `destroy_github_repo`, `lgit`, and a `claude` wrapper that injects `GITHUB_PAT` from 1Password.
- `zsh/.config/zsh/aliases.zsh` — aliases (includes `vim=nvim`, `R='R --no-save'`, platform-conditional `l`).
- `zsh/.config/zsh/exports.zsh` — PATH additions (via `add_to_path`) and secret exports. **Re-sources `functions.zsh`** because it depends on `add_to_path`; the sentinel prevents re-running the function defs.

When adding PATH entries, use `add_to_path <dir>` (prepends) or `add_to_path -e <dir>` (appends). It is idempotent.

## Secret handling

`exports.zsh` populates several env vars on shell startup by shelling out to external credential stores. These will fail silently or prompt if the store is locked:

- `MEM0_API_KEY` — macOS Keychain (`security find-generic-password -s mem0-vade-coo`)
- `LIBRARY_BEARER`, `VADE_AUTH_TOKEN` — 1Password CLI (`op read ...`)
- `GH_TOKEN` — `gh auth token`

On macOS, `SSH_AUTH_SOCK` points at the 1Password SSH agent. SSH keys are managed by 1Password, not `~/.ssh/`.

Never commit real secret values. Anything read from `op` / `security` / `gh` stays external.

## Conventions when editing

- **Don't add new top-level dotfiles at the repo root** — they won't be stowed. Put them inside a package under the path they should occupy in `$HOME`.
- **Don't hardcode `/Users/venpopov`** in new config. Use `$HOME`, `$XDG_CONFIG_HOME`, `$ZDOTDIR`, etc.
- Platform-specific blocks use `case "$(uname -s)" in Darwin) ... ;; Linux) ... ;; esac`. Follow that shape rather than bare `if [[ $(uname) = ... ]]`.
- Git global ignores live in `git/.gitignore_global` (referenced by `git/.gitconfig` via `core.excludesfile`). Add patterns there, not per-repo, for things that should be ignored everywhere.
