# Load my zsh modules
source "${ZDOTDIR:-${HOME}/.config/zsh}"/functions.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/aliases.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/exports.zsh

# Colorize man pages and --help output with bat (only if bat is installed).
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
fi

# fzf key bindings and fuzzy completion. `--zsh` only exists on fzf >= 0.48
# (newer than Ubuntu 24.04's apt-shipped 0.44). Suppress stderr so older
# installations don't pollute the shell startup; `source <empty>` is harmless.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh 2>/dev/null)
fi




source "${ZDOTDIR:-${HOME}/.config/zsh}"/dotfiles-sync.zsh

[ -f "${HOME}/.ghcup/env" ] && . "${HOME}/.ghcup/env" # ghcup-env

# Ensure .zshrc exits 0 even if the last test above was false. Matters for
# non-interactive `zsh -ic 'cmd'` callers (CI smoke checks); harmless otherwise.
true
