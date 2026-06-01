# dotfiles

Personal dotfiles, deployed to `$HOME` via GNU Stow. Same repo works on macOS
(macbook + mac studio) and ephemeral Linux cloud servers.

## Quick start

### macOS (fresh machine)

```sh
# install brew first — https://brew.sh
git clone git@github.com:venpopov/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh --bootstrap
```

### Linux (ephemeral cloud server)

```sh
# apt: see install/apt.pkgs
git clone git@github.com:venpopov/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh --minimal
```

### Subsequent syncs (any machine)

The office-mac / second-machine ritual:

```sh
dotsync                       # pull latest dotfiles from origin
bash install.sh --doctor      # read-only drift check; exits 1 if anything's off
bash install.sh               # idempotent re-stow + run any new install hooks
```

Variants:

```sh
bash install.sh --dry-run     # see what would change without doing it
bash install.sh --bootstrap   # install brew + Brewfile + macOS defaults
                              # + Touch ID + duti + (MAS apps unless
                              # BOOTSTRAP_SKIP_AUTH=1)
```

### Testing the dotfiles themselves

```sh
make install-dev              # one-time: install bats-core + shellcheck + gitleaks
make lint                     # shellcheck + bash -n + zsh -n on all scripts
make test-unit                # bats unit tests
make test-integration         # Docker-based Linux integration (requires Docker)
make doctor                   # alias for bash install.sh --doctor
```

CI runs lint + unit-tests + secrets-scan + linux-integration on every push.
A separate macOS workflow runs the full bootstrap on a fresh `macos-14` runner.

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
