#!/usr/bin/env bats
# Tests for install/lib.sh (currently: read_pkgs).

load '../helpers/setup'

setup() {
  setup_test_home
  # shellcheck disable=SC1091
  source "$BATS_TEST_DIRNAME/../../install/lib.sh"
}

teardown() {
  teardown_test_home
}

@test "read_pkgs returns empty + status 0 for a missing file" {
  run read_pkgs "$BATS_TEST_TMPDIR/does-not-exist"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "read_pkgs returns one line per non-comment non-blank line" {
  cat > "$BATS_TEST_TMPDIR/pkgs" <<EOF
zsh
git
# this is a comment
gh

stow
EOF
  run read_pkgs "$BATS_TEST_TMPDIR/pkgs"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" = "zsh" ]
  [ "${lines[1]}" = "git" ]
  [ "${lines[2]}" = "gh" ]
  [ "${lines[3]}" = "stow" ]
}

@test "read_pkgs skips leading-whitespace comments" {
  cat > "$BATS_TEST_TMPDIR/pkgs" <<EOF
zsh
   # indented comment
git
EOF
  run read_pkgs "$BATS_TEST_TMPDIR/pkgs"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "read_pkgs skips whitespace-only blank lines" {
  printf 'zsh\n   \ngit\n' > "$BATS_TEST_TMPDIR/pkgs"
  run read_pkgs "$BATS_TEST_TMPDIR/pkgs"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "zsh" ]
  [ "${lines[1]}" = "git" ]
}

@test "read_pkgs returns nothing for an all-comments file" {
  printf '# a\n# b\n   # c\n' > "$BATS_TEST_TMPDIR/pkgs"
  run read_pkgs "$BATS_TEST_TMPDIR/pkgs"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "read_pkgs handles the real install/common.pkgs file" {
  run read_pkgs "$BATS_TEST_DIRNAME/../../install/common.pkgs"
  [ "$status" -eq 0 ]
  # common.pkgs has at least zsh, git, gh, ssh — assert known content present.
  [[ "$output" == *"zsh"* ]]
  [[ "$output" == *"git"* ]]
}
