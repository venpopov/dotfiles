#!/usr/bin/env bats
# Tests for _dotfiles_status_line() from zsh/.config/zsh/dotfiles-sync.zsh.
# The function uses `git rev-list --count` against `@{u}` — easiest to test
# by setting up a real temp git repo with a controlled ahead/behind/dirty
# state, then invoking the function under zsh.

load '../helpers/setup'

SYNC="$BATS_TEST_DIRNAME/../../zsh/.config/zsh/dotfiles-sync.zsh"

# Create a working repo cloned from a bare origin, ready to be tweaked
# into ahead/behind/dirty states. Returns the working repo path on stdout.
make_repo() {
  local origin="$BATS_TEST_TMPDIR/origin"
  local repo="$HOME/dotfiles"
  git init --quiet --bare "$origin"
  git init --quiet -b main "$repo"
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name  "Test User"
  git -C "$repo" remote add origin "$origin"
  echo "v1" > "$repo/README"
  git -C "$repo" add README
  git -C "$repo" commit --quiet -m "init"
  git -C "$repo" push --quiet -u origin main
  echo "$repo"
}

# Run the status_line function under zsh against $repo and capture output.
run_status_line() {
  local repo="$1"
  run zsh -c "DOTFILES_DIR='$repo'; source '$SYNC'; _dotfiles_status_line"
}

setup()    { setup_test_home; }
teardown() { teardown_test_home; }

@test "clean repo (synced + no dirty) → empty output" {
  local repo
  repo=$(make_repo)
  run_status_line "$repo"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "uncommitted changes → reports dirty>0" {
  local repo
  repo=$(make_repo)
  echo "modified" >> "$repo/README"
  run_status_line "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dirty=1"* ]]
  [[ "$output" == *"dotsync"* ]]
}

@test "untracked file → reports dirty>0" {
  local repo
  repo=$(make_repo)
  echo "new" > "$repo/newfile"
  run_status_line "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dirty=1"* ]]
}

@test "branch ahead of origin → reports ahead>0" {
  local repo
  repo=$(make_repo)
  echo "v2" > "$repo/README"
  git -C "$repo" commit --quiet -am "v2"
  run_status_line "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ahead=1"* ]]
  [[ "$output" == *"behind=0"* ]]
  [[ "$output" == *"dirty=0"* ]]
}

@test "branch behind origin → reports behind>0" {
  local repo
  repo=$(make_repo)
  # Push a second commit through a second clone, then update repo's ref pointer.
  local twin="$BATS_TEST_TMPDIR/twin"
  git clone --quiet "$BATS_TEST_TMPDIR/origin" "$twin"
  git -C "$twin" config user.email "test@example.com"
  git -C "$twin" config user.name  "Test User"
  echo "v2" > "$twin/README"
  git -C "$twin" commit --quiet -am "v2"
  git -C "$twin" push --quiet origin main
  git -C "$repo" fetch --quiet
  run_status_line "$repo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"behind=1"* ]]
  [[ "$output" == *"ahead=0"* ]]
}
