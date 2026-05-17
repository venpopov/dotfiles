#!/bin/sh
alias t='tree'
alias R='R --no-save'
alias r="radian"
alias python="python3"
alias qp="quarto preview --render all"
alias update_website="quarto publish gh-pages --no-prompt --no-render --no-browser"
alias create_temp_dir='temp_dir=$(mktemp -d) && cd $temp_dir'
alias gs='git status'
alias gd='git diff'
alias vim='nvim'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Deal with different platform settings
case "$(uname -s)" in
  Darwin)
    alias l='ls -lAhG'
    ;;

  Linux)
    alias l='ls -lAh --color=auto'
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    ;;
  *)
    ;;
esac
