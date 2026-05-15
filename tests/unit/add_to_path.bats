#!/usr/bin/env bats
# Tests for add_to_path() from zsh/.config/zsh/functions.zsh.
# The function is POSIX-style under a `#!/bin/sh` header with bash-compatible
# guards, so it sources fine in bash (bats's default shell).

load '../helpers/setup'

setup() {
  setup_test_home
  # Save real PATH — tests overwrite it, but bats's internal teardown needs
  # `rm`, `mkdir`, etc. on PATH. Restored in teardown.
  ORIG_PATH="$PATH"
  # Bypass the sourcing-guard sentinel so we always reload fresh.
  unset FUNCTIONS_ZSH_LOADED
  # shellcheck disable=SC1091
  source "$BATS_TEST_DIRNAME/../../zsh/.config/zsh/functions.zsh"
  export PATH="/usr/bin:/bin"
}

teardown() {
  export PATH="$ORIG_PATH"
  teardown_test_home
}

@test "add_to_path prepends a new dir by default" {
  add_to_path "/foo/bin"
  [ "$PATH" = "/foo/bin:/usr/bin:/bin" ]
}

@test "add_to_path with --end appends" {
  add_to_path --end "/foo/bin"
  [ "$PATH" = "/usr/bin:/bin:/foo/bin" ]
}

@test "add_to_path with -e appends (short flag)" {
  add_to_path -e "/foo/bin"
  [ "$PATH" = "/usr/bin:/bin:/foo/bin" ]
}

@test "add_to_path is idempotent on repeated prepend" {
  add_to_path "/foo/bin"
  add_to_path "/foo/bin"
  [ "$PATH" = "/foo/bin:/usr/bin:/bin" ]
}

@test "add_to_path is idempotent on repeated append" {
  add_to_path -e "/foo/bin"
  add_to_path -e "/foo/bin"
  [ "$PATH" = "/usr/bin:/bin:/foo/bin" ]
}

@test "add_to_path detects a dir already in the middle of PATH" {
  export PATH="/head:/middle:/tail"
  add_to_path "/middle"
  [ "$PATH" = "/head:/middle:/tail" ]
}

@test "add_to_path with an empty PATH still works" {
  export PATH=""
  add_to_path "/foo/bin"
  [ "$PATH" = "/foo/bin" ]
}
