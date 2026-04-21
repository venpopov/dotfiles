# Drift detector for the dotfiles repo. Sourced from .zshrc. Runs once per
# interactive shell: fetches origin at most every 4h, prints one line if the
# working tree is dirty or the branch is ahead/behind.

# Locate the dotfiles repo — works whether cloned to ~/.dotfiles or ~/dotfiles.
for _candidate in "$HOME/.dotfiles" "$HOME/dotfiles"; do
  if [[ -d "$_candidate/.git" ]]; then
    DOTFILES_DIR="$_candidate"
    break
  fi
done
unset _candidate
[[ -z "${DOTFILES_DIR:-}" ]] && return 0
export DOTFILES_DIR

_dotfiles_fetch_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/last_fetch"
_dotfiles_fetch_ttl=14400   # 4h

_dotfiles_maybe_fetch() {
  mkdir -p "${_dotfiles_fetch_stamp:h}"
  local now last=0
  now=$(date +%s)
  [[ -f "$_dotfiles_fetch_stamp" ]] && last=$(<"$_dotfiles_fetch_stamp")
  (( now - last < _dotfiles_fetch_ttl )) && return 0
  (git -C "$DOTFILES_DIR" fetch --quiet origin &) 2>/dev/null
  echo "$now" > "$_dotfiles_fetch_stamp"
}

_dotfiles_status_line() {
  local ahead behind dirty
  ahead=$(git -C "$DOTFILES_DIR" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  behind=$(git -C "$DOTFILES_DIR" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
  dirty=$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if (( ahead + behind + dirty > 0 )); then
    echo "dotfiles: ahead=$ahead behind=$behind dirty=$dirty — run 'dotsync' / 'dotpush'"
  fi
}

_dotfiles_maybe_fetch
_dotfiles_status_line
