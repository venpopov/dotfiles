#!/usr/bin/env bash
# Symlink ~/Downloads -> iCloud Drive Downloads so the Mac shares its
# Downloads folder with iOS/iPadOS (which use iCloud Drive's Downloads by
# default). Idempotent. macOS only.
# Usage: bash install/icloud-downloads.sh [--dry-run]
set -euo pipefail

DRY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "icloud-downloads: skip (not Darwin)"
  exit 0
fi

icloud_root="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
icloud_dl="$icloud_root/Downloads"
local_dl="$HOME/Downloads"

# CloudDocs only exists once the user enables iCloud Drive in System Settings.
# Don't mkdir it ourselves — that would create a non-syncing folder.
if [[ ! -d "$icloud_root" ]]; then
  echo "==> iCloud Drive not enabled — skip ~/Downloads link"
  echo "    Enable it in System Settings → Apple ID → iCloud Drive,"
  echo "    then re-run: bash install.sh"
  exit 0
fi

# Already linked to the right place? No-op.
if [[ -L "$local_dl" ]]; then
  current="$(readlink "$local_dl")"
  if [[ "$current" == "$icloud_dl" ]]; then
    echo "==> ~/Downloads already linked to iCloud Drive Downloads"
    exit 0
  fi
  echo "==> ~/Downloads is a symlink to:" >&2
  echo "    $current" >&2
  echo "    Refusing to replace. Remove it manually if you want the iCloud target." >&2
  exit 1
fi

# Ensure the target folder exists inside iCloud Drive.
if [[ ! -d "$icloud_dl" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "(dry-run) mkdir -p $icloud_dl"
  else
    mkdir -p "$icloud_dl"
    echo "==> created $icloud_dl"
  fi
fi

# Migrate ~/Downloads contents into the iCloud target.
if [[ -d "$local_dl" && ! -L "$local_dl" ]]; then
  # nullglob: empty dir yields an empty array, not a literal "$local_dl/*".
  # dotglob: include hidden files so .gitconfig-style intentional dotfiles
  # aren't silently left behind to block rmdir later.
  shopt -s nullglob dotglob
  items=("$local_dl"/*)
  shopt -u nullglob dotglob

  if (( ${#items[@]} > 0 )); then
    echo "==> migrating contents of ~/Downloads to iCloud Downloads"
    skipped=()
    for item in "${items[@]}"; do
      name="${item##*/}"
      target="$icloud_dl/$name"

      # .DS_Store is disposable Finder metadata — never migrate, never conflict.
      if [[ "$name" == ".DS_Store" ]]; then
        if [[ "$DRY" -eq 1 ]]; then
          printf '  (dry-run) rm: %s\n' "$name"
        else
          rm -f "$item"
        fi
        continue
      fi

      if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$DRY" -eq 1 ]]; then
          printf '  (dry-run) skip (conflict): %s\n' "$name"
        else
          skipped+=("$name")
        fi
        continue
      fi

      if [[ "$DRY" -eq 1 ]]; then
        printf '  (dry-run) mv: %s\n' "$name"
      else
        # Same filesystem under $HOME → mv is a rename; xattrs (including
        # com.apple.quarantine) are preserved exactly.
        mv "$item" "$target"
      fi
    done

    if (( ${#skipped[@]} > 0 )); then
      echo "==> Name conflicts in iCloud Downloads — left in ~/Downloads:" >&2
      printf '    %s\n' "${skipped[@]}" >&2
      echo "    Resolve manually (delete duplicate or rename), then re-run." >&2
      exit 1
    fi
  fi
fi

# Remove the (now empty) ~/Downloads. macOS protects ~/Downloads via TCC; without
# Full Disk Access, rmdir returns EACCES even on an empty directory.
if [[ -d "$local_dl" && ! -L "$local_dl" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "(dry-run) rmdir $local_dl"
    echo "(dry-run) ln -s \"$icloud_dl\" $local_dl"
    exit 0
  fi
  if ! rmdir "$local_dl" 2>/dev/null; then
    cat >&2 <<EOF
==> Cannot remove ~/Downloads (likely TCC / Full Disk Access).

    macOS protects ~/Downloads at the kernel level; rmdir is blocked even
    when the directory is empty. Pick one and re-run \`bash install.sh\`:

    A) Grant your terminal Full Disk Access (persistent fix):
       System Settings → Privacy & Security → Full Disk Access → add your
       terminal app (Terminal, iTerm, Ghostty, etc.), then re-run.

    B) One-shot, no FDA grant needed:
         sudo rmdir ~/Downloads
         ln -s "$icloud_dl" ~/Downloads
EOF
    exit 1
  fi
fi

if [[ "$DRY" -eq 1 ]]; then
  echo "(dry-run) ln -s \"$icloud_dl\" $local_dl"
  exit 0
fi
ln -s "$icloud_dl" "$local_dl"
echo "==> linked ~/Downloads -> $icloud_dl"
