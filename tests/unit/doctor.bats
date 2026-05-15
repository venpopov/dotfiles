#!/usr/bin/env bats
# Smoke tests for install/doctor.sh. The orchestration logic is mostly thin
# — it delegates to stow, brew bundle check, git. We verify it runs without
# crashing and produces the expected sectioned output structure.

load '../helpers/setup'

DOCTOR="$BATS_TEST_DIRNAME/../../install/doctor.sh"

setup() {
  setup_test_home
  ORIG_PATH="$PATH"
}

teardown() {
  export PATH="$ORIG_PATH"
  teardown_test_home
}

@test "doctor exits 0 or 1 — never crashes" {
  run bash "$DOCTOR"
  # 0 = all in sync, 1 = drift; either is a valid signal.
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "doctor prints every section header" {
  run bash "$DOCTOR"
  [[ "$output" == *"=== Symlinks ==="* ]]
  [[ "$output" == *"=== Stow ==="* ]]
  [[ "$output" == *"=== Git sync ==="* ]]
  # Either Brewfile (Darwin) or apt packages (Linux) — depending on the
  # CI/local host. Assert one of them shows up.
  [[ "$output" == *"=== Brewfile ==="* ]] || [[ "$output" == *"=== apt packages ==="* ]]
}

@test "doctor reports drift when \$HOME is empty (no stowed symlinks)" {
  # Fresh isolated $HOME has none of the expected symlinks.
  run bash "$DOCTOR"
  [ "$status" -eq 1 ]
  [[ "$output" == *"==> doctor: drift detected"* ]]
}

@test "doctor's last line is a clear status summary" {
  run bash "$DOCTOR"
  # bash 3 (default on macOS) doesn't support negative-index array access.
  local last_idx=$(( ${#lines[@]} - 1 ))
  local last="${lines[$last_idx]}"
  [[ "$last" == *"doctor:"* ]]
}

@test "install.sh rejects --doctor combined with --bootstrap" {
  local installsh="$BATS_TEST_DIRNAME/../../install.sh"
  run bash "$installsh" --doctor --bootstrap
  [ "$status" -eq 2 ]
  [[ "$output" == *"cannot be combined"* ]]
}
