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

  Rscript -e "renv::deactivate(clean = TRUE)"
  
  # Delete the local folder and the remote repository
  cd ..
  rm -fr "$proj" && gh repo delete "$remote_url" --yes
}


claude() {
  GITHUB_PAT=$(op read 'op://dev/vade-coo-mcp-2026-04/credential') command claude "$@"
}


# Lazy git
lgit() {
  git add .
  git commit -a -m "$1"
  git push
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
