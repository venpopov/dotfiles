# Load my zsh modules
source "${ZDOTDIR:-${HOME}/.config/zsh}"/functions.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/aliases.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/exports.zsh

# Colorize man pages and --help output with bat (only if bat is installed).
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
fi

# fzf key bindings and fuzzy completion (only if fzf is installed).
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi




source "${ZDOTDIR:-${HOME}/.config/zsh}"/dotfiles-sync.zsh

[ -f "${HOME}/.ghcup/env" ] && . "${HOME}/.ghcup/env" # ghcup-env
