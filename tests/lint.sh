#!/usr/bin/env bash
# Static lint over all shell scripts in the repo.
# Called by `make lint` and by .github/workflows/ci.yml.
# Requires shellcheck + zsh in $PATH.
set -euo pipefail

cd "$(dirname "$0")/.."

# Collect every .sh file under install.sh, install/, tests/.
mapfile -d '' -t sh_files < <(
  find install.sh install tests -name "*.sh" -type f -print0
)

echo "==> shellcheck (${#sh_files[@]} files)"
shellcheck "${sh_files[@]}"

echo "==> bash -n"
for f in "${sh_files[@]}"; do
  bash -n "$f"
done

echo "==> zsh -n"
while IFS= read -r -d '' f; do
  zsh -n "$f"
done < <(find zsh -type f \( -name "*.zsh" -o -name ".zshrc" -o -name ".zshenv" -o -name ".zprofile" \) -print0)

echo "==> lint passed"
