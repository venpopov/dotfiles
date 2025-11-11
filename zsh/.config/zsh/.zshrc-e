# Load my zsh modules
source "${ZDOTDIR:-${HOME}/.config/zsh}"/functions.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/aliases.zsh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/exports.zsh

# Setup Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Enable Powerlevel10k instant prompt. To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
 source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source ~/.powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Colorize man pages with bat
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'


# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)



