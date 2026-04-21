# dotfiles

Personal dotfiles, deployed to `$HOME` via GNU Stow. Same repo works on macOS
(macbook + mac studio) and ephemeral Linux cloud servers.

## Quick start

### macOS (fresh machine)

```sh
# install brew first — https://brew.sh
git clone git@github.com:venpopov/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh --bootstrap
```

### Linux (ephemeral cloud server)

```sh
# apt: see install/apt.pkgs
git clone git@github.com:venpopov/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh --minimal
```

### Subsequent syncs (any machine)

```sh
bash install.sh              # idempotent re-stow
bash install.sh --dry-run    # see what would change
```

## Layout

See `CLAUDE.md` for the stow-package layout and zsh module wiring.

## Secrets

`git` and `gh` always work without priming. All other 1Password-backed secrets
are lazy — call `library_bearer`, `vade_auth_token`, or `claude` at use site.
`op signin` prompts then, not on shell startup.

## Conventions

- Don't add top-level dotfiles at the repo root — they won't be stowed.
- Use `$HOME`, `$XDG_CONFIG_HOME`, `$ZDOTDIR` — never `/Users/venpopov`.
- Platform branches use `case "$(uname -s)" in Darwin) ... ;; Linux) ... ;;`.
