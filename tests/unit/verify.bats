#!/usr/bin/env bats
# Tests for install/verify.sh against mocked symlink states under a temp $HOME.

load '../helpers/setup'

VERIFY="$BATS_TEST_DIRNAME/../../install/verify.sh"

# Build the full expected post-stow tree under $HOME so verify.sh passes.
build_passing_tree() {
  # .zshenv → real file
  touch "$BATS_TEST_TMPDIR/zshenv_target"
  ln -s "$BATS_TEST_TMPDIR/zshenv_target" "$HOME/.zshenv"

  # .config/zsh/ → dir with zshrc/exports/functions inside
  mkdir -p "$BATS_TEST_TMPDIR/zsh_target"
  touch "$BATS_TEST_TMPDIR/zsh_target/.zshrc"
  touch "$BATS_TEST_TMPDIR/zsh_target/exports.zsh"
  touch "$BATS_TEST_TMPDIR/zsh_target/functions.zsh"
  mkdir -p "$HOME/.config"
  ln -s "$BATS_TEST_TMPDIR/zsh_target" "$HOME/.config/zsh"

  # .gitconfig + .gitignore_global → real-file targets
  touch "$BATS_TEST_TMPDIR/gitconfig" "$BATS_TEST_TMPDIR/gitignore_global"
  ln -s "$BATS_TEST_TMPDIR/gitconfig"        "$HOME/.gitconfig"
  ln -s "$BATS_TEST_TMPDIR/gitignore_global" "$HOME/.gitignore_global"

  # .ssh/config → real file (stow may fold or unfold; verify.sh uses -e, not -L)
  mkdir -p "$HOME/.ssh"
  touch "$HOME/.ssh/config"
}

setup()    { setup_test_home; }
teardown() { teardown_test_home; }

@test "verify.sh passes when the full expected tree exists" {
  build_passing_tree
  run bash "$VERIFY"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "missing .zshenv symlink → fail with MISSING SYMLINK message" {
  build_passing_tree
  rm "$HOME/.zshenv"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING SYMLINK: $HOME/.zshenv"* ]]
}

@test ".zshenv as a regular file (not symlink) → fail" {
  build_passing_tree
  rm "$HOME/.zshenv"
  echo "fake" > "$HOME/.zshenv"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING SYMLINK: $HOME/.zshenv"* ]]
}

@test "missing .config/zsh symlink → fail" {
  build_passing_tree
  rm "$HOME/.config/zsh"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING SYMLINK: $HOME/.config/zsh"* ]]
}

@test "missing exports.zsh inside stowed dir → fail with MISSING (not symlink)" {
  build_passing_tree
  rm "$BATS_TEST_TMPDIR/zsh_target/exports.zsh"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING: $HOME/.config/zsh/exports.zsh"* ]]
}

@test "missing .ssh/config → fail" {
  build_passing_tree
  rm "$HOME/.ssh/config"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *"MISSING: $HOME/.ssh/config"* ]]
}

@test "multiple failures are all reported" {
  build_passing_tree
  rm "$HOME/.zshenv"
  rm "$HOME/.gitconfig"
  run bash "$VERIFY"
  [ "$status" -eq 1 ]
  [[ "$output" == *".zshenv"* ]]
  [[ "$output" == *".gitconfig"* ]]
}
