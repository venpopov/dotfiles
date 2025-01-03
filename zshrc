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
export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib -L/opt/homebrew/opt/libxml2/lib -L/opt/homebrew/opt/icu4c@76/lib"
export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include -I/opt/homebrew/opt/libxml2/include -I/opt/homebrew/opt/icu4c@76/include"
export PATH="/opt/homebrew/opt/libxml2/bin:/opt/homebrew/opt/icu4c@76/bin:$PATH"
export DYLD_LIBRARY_PATH="/opt/homebrew/opt/icu4c@76/lib:$DYLD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libxml2/lib/pkgconfig:/opt/homebrew/opt/icu4c@76/lib/pkgconfig"

export PATH="/opt/homebrew/opt/libxml2/bin:$PATH"
export PATH="$HOME/scripts:$PATH"

export EDITOR="code"
export VISUAL="code"
export RSTUDIO_WHICH_R=/usr/local/bin/R

# custom programs/aliases
alias qp="quarto preview --render all"
alias update_website="rsync -avz --progress --delete --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r ~/venpopov.com/_site/ venpopov.com:/home4/venpopov/public_html/"
alias create_temp_dir='temp_dir=$(mktemp -d) && cd $temp_dir'

# Added by Windsurf
export PATH="/Users/vpopov/.codeium/windsurf/bin:$PATH"
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
alias ls='ls -l'
alias r="radian"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/Users/vpopov/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<

# Lazy git
function lgit() {
  git add .
  git commit -a -m "$1"
  git push
}
