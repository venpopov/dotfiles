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
# cmdstan path from cache — refresh via `refresh_cmdstan_path` (see functions.zsh).
# The if-form (instead of `&& add_to_path "$(<…)"`) avoids zsh's parse-time
# evaluation of `$(<file)`, which otherwise emits a benign-but-noisy stderr
# warning under `zsh -n` when the cache file is absent.
_cmdstan_cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/cmdstan_path"
if [[ -s "$_cmdstan_cache" ]]; then
  _cmdstan_p=$(<"$_cmdstan_cache")
  add_to_path "$_cmdstan_p/bin"
  unset _cmdstan_p
fi
[[ -r "$HOME/.opam/opam-init/init.zsh" ]] && source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1

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


if command -v security >/dev/null 2>&1; then
  export MEM0_API_KEY="$(security find-generic-password -s mem0-vade-coo -w 2>/dev/null)"
fi
# LIBRARY_BEARER / VADE_AUTH_TOKEN are lazy — call library_bearer / vade_auth_token
# at use site. See functions.zsh.
if command -v gh >/dev/null 2>&1; then
  export GH_TOKEN="$(gh auth token 2>/dev/null)"
fi


