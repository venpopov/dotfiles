#!/bin/sh
# Guard against multiple sourcing
[[ -n "$FUNCTIONS_ZSH_LOADED" ]] && return
FUNCTIONS_ZSH_LOADED=1


destroy_github_repo() {
  local proj="$1"
  
  # Check if the folder exists
  if [[ ! -d "$proj" ]]; then
    echo "Directory $proj does not exist."
    return 1
  fi
  
  # Check if the folder is a git repository
  if [[ ! -d "$proj/.git" ]]; then
    echo "Directory $proj is not a git repository."
    return 1
  fi
  
  # Check if there is a remote repository
  cd "$proj" || return 1
  local remote_url
  remote_url=$(git remote get-url origin)
  
  if [[ -z "$remote_url" ]]; then
    echo "No remote repository found for $proj."
    return 1
  fi

  if command -v Rscript >/dev/null 2>&1; then
    Rscript -e "renv::deactivate(clean = TRUE)"
  fi
  
  # Delete the local folder and the remote repository
  cd ..
  rm -fr "$proj" && gh repo delete "$remote_url" --yes
}


: ${CLAUDE_VAULT_ITEM:=vade-coo-mcp-2026-04}
# 1Password item: "Service Account Auth Token: vade-coo-sandbox" in vault COO.
# Referenced by UUID because op secret references reject ':' in item titles.
# If the item is recreated, update this ID (or rename the item to drop the
# colon and switch to a title-based ref).
: ${COO_SA_TOKEN_REF:='op://COO/7mbzzpzdxjddjm2ltcar6p3cfa/credential'}
claude() {
  # Inject secrets that .mcp.json templates need at claude's exec time.
  # Done here (not eagerly in exports.zsh) so shell startup stays prompt-free.
  local -a env_prefix
  env_prefix=(
    GITHUB_MCP_PAT="$(op read "op://dev/${CLAUDE_VAULT_ITEM}/credential")"
    VADE_AUTH_TOKEN="$(vade_auth_token)"

  )
  # When launched from a vade-app project, also pass the COO service-account
  # token + GIT_CONFIG_GLOBAL so vade-runtime/scripts/local-setup.sh can run
  # the full coo-bootstrap (SSH keys, gitconfig, MCP env vars). Scoped to
  # $PWD so commits from a normal terminal keep the user's personal identity.
  if [[ "$PWD" == "$HOME/GitHub/vade-app"* ]]; then
    env_prefix+=(
      OP_SERVICE_ACCOUNT_TOKEN="$(op read "$COO_SA_TOKEN_REF")"
      GIT_CONFIG_GLOBAL="$HOME/.vade/gitconfig-coo"
    )
    export GITHUB_PAT="$(op read "op://dev/${CLAUDE_VAULT_ITEM}/credential")"
  fi
  env "${env_prefix[@]}" command claude "$@"
}


# Lazy 1Password secrets. Biometric prompt fires when called, not at shell start.
library_bearer() {
  command -v op >/dev/null 2>&1 || { echo "op not installed" >&2; return 1; }
  op read 'op://dev/VADE library bearer/password'
}

vade_auth_token() {
  command -v op >/dev/null 2>&1 || { echo "op not installed" >&2; return 1; }
  op read 'op://dev/vade-app.dev/password'
}

# Refresh the cmdstan path cache. Run once per machine, or after
# cmdstanr::install_cmdstan() / switching R installations.
refresh_cmdstan_path() {
  command -v Rscript >/dev/null 2>&1 || { echo "Rscript not found" >&2; return 1; }
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/cmdstan_path"
  mkdir -p "${cache:h}"
  Rscript --vanilla -e 'cat(cmdstanr::cmdstan_path())' > "$cache"
  echo "cached: $(<"$cache")"
}


# Lazy git
lgit() {
  git add .
  git commit -a -m "$1"
  git push
}


# Pull the dotfiles repo.
dotsync() {
  local d="${DOTFILES_DIR:-}"
  if [[ -z "$d" ]]; then
    for c in "$HOME/.dotfiles" "$HOME/dotfiles"; do
      [[ -d "$c/.git" ]] && { d="$c"; break; }
    done
  fi
  [[ -z "$d" ]] && { echo "dotfiles repo not found" >&2; return 1; }
  git -C "$d" pull --ff-only && git -C "$d" status --short
}

# Stage-all, commit with a message, push.
dotpush() {
  local d="${DOTFILES_DIR:-}"
  if [[ -z "$d" ]]; then
    for c in "$HOME/.dotfiles" "$HOME/dotfiles"; do
      [[ -d "$c/.git" ]] && { d="$c"; break; }
    done
  fi
  [[ -z "$d" ]] && { echo "dotfiles repo not found" >&2; return 1; }
  local msg="${1:-sync}"
  git -C "$d" add -A && git -C "$d" commit -m "$msg" && git -C "$d" push
}


# Function to add a directory to PATH only if it's not already present
# Usage: add_to_path [-e|--end] directory
add_to_path() {
  local append_to_end=false
  local dir=""
  
  # Parse arguments
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -e|--end)
        append_to_end=true
        shift
        ;;
      *)
        dir="$1"
        shift
        ;;
    esac
  done
  
  # Check if the directory is already in PATH
  case ":$PATH:" in
    *:"$dir":*)
      # Directory is already in PATH, do nothing
      ;;
    *)
      # Directory is not in PATH, add it
      if [ "$append_to_end" = true ]; then
        export PATH="${PATH:+${PATH}:}$dir"  # Add to end
      else
        export PATH="$dir${PATH:+:${PATH}}"  # Add to beginning
      fi
      ;;
  esac
}
