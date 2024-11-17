autoload -Uz compinit && compinit
function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

COLOR_DEF=$'%f'
COLOR_USR=$'%F{243}'
COLOR_DIR=$'%F{197}'
COLOR_GIT=$'%F{39}'
setopt PROMPT_SUBST
export PROMPT='${COLOR_USR}%n ${COLOR_DIR}%~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF} $ '

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export LC_ALL=en_US.UTF-8
export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include"
export LDFLAGS="-L/opt/homebrew/opt/libxml2/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libxml2/include"

export PATH="/opt/homebrew/opt/libxml2/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

export EDITOR="code"
export VISUAL="code"
export RSTUDIO_WHICH_R=/opt/homebrew/bin/R

# custom programs/aliases
alias qp="quarto preview --render all"
alias update_website="rsync -avz --progress --delete ~/venpopov.com/_site/ venpopov.com:/home4/venpopov/public_html/"
alias create_temp_dir='temp_dir=$(mktemp -d) && cd $temp_dir'
