# Load my zsh modules
source "${ZDOTDIR:-${HOME}/.config/zsh}"/functions.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/aliases.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/exports.zsh

# Colorize man pages with bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'


# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)




source "${ZDOTDIR:-${HOME}/.config/zsh}"/dotfiles-sync.zsh

[ -f "${HOME}/.ghcup/env" ] && . "${HOME}/.ghcup/env" # ghcup-env
