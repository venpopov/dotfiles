#!/bin/sh
source "${ZDOTDIR:-${HOME}/.config/zsh}"/functions.zsh

HISTSIZE=1000000
SAVEHIST=1000000
export LC_ALL=en_US.UTF-8

export DEV_DIR=$HOME/GitHub
add_to_path $HOME/bin
add_to_path $HOME/.local/bin
add_to_path $HOME/.juliaup/bin
add_to_path $HOME/.cargo/bin
add_to_path $HOME/.fly/bin
add_to_path $(Rscript --vanilla -e 'cat(cmdstanr::cmdstan_path())')/bin
[[ ! -r '$HOME/.opam/opam-init/init.zsh' ]] || source '$HOME/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null

# Deal with different platform settings
case "$(uname -s)" in
  Darwin)
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    ;;

  Linux)
    ;;

  CYGWIN* | MINGW32* | MSYS* | MINGW*)
    ;;

  *)
    ;;
esac


export MEM0_API_KEY="$(security find-generic-password -s mem0-vade-coo -w 2>/dev/null)"
export LIBRARY_BEARER="$(op read 'op://dev/VADE library bearer/password')"
export VADE_AUTH_TOKEN="$(op read 'op://dev/vade-app.dev/password')"
#export GH_TOKEN="$(gh auth token 2>/dev/null)"


