#!/usr/bin/env bats
# Tests for install/icloud-downloads.sh — the state-machine logic.
# Runs on any platform: we mock `uname` (force Darwin) via PATH shim and
# fabricate the CloudDocs directory under $HOME.

load '../helpers/setup'

ICLOUD_REL='Library/Mobile Documents/com~apple~CloudDocs'
SCRIPT="$BATS_TEST_DIRNAME/../../install/icloud-downloads.sh"

setup() {
  setup_test_home
  # Force `uname -s` → Darwin so the script doesn't early-exit on Linux.
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/uname" <<'EOF'
#!/usr/bin/env bash
echo "Darwin"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/uname"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  # Fabricate the CloudDocs root so the script doesn't bail "iCloud not enabled".
  mkdir -p "$HOME/$ICLOUD_REL"
}

teardown() {
  teardown_test_home
}

@test "no-op when ~/Downloads is already linked to the iCloud target" {
  mkdir -p "$HOME/$ICLOUD_REL/Downloads"
  ln -s "$HOME/$ICLOUD_REL/Downloads" "$HOME/Downloads"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already linked"* ]]
  [ -L "$HOME/Downloads" ]
}

@test "refuses to clobber a symlink pointing elsewhere" {
  mkdir -p "$HOME/other"
  ln -s "$HOME/other" "$HOME/Downloads"

  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Refusing to replace"* ]]
  # Original symlink untouched.
  [ "$(readlink "$HOME/Downloads")" = "$HOME/other" ]
}

@test "exits cleanly when iCloud Drive isn't enabled" {
  rm -rf "$HOME/$ICLOUD_REL"
  mkdir -p "$HOME/Downloads"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"iCloud Drive not enabled"* ]]
  # ~/Downloads is untouched (still a real dir).
  [ -d "$HOME/Downloads" ]
  [ ! -L "$HOME/Downloads" ]
}

@test "creates iCloud target dir when missing, then links" {
  mkdir -p "$HOME/Downloads"
  # iCloud Downloads doesn't exist yet — only the CloudDocs root.

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -d "$HOME/$ICLOUD_REL/Downloads" ]
  [ -L "$HOME/Downloads" ]
  [ "$(readlink "$HOME/Downloads")" = "$HOME/$ICLOUD_REL/Downloads" ]
}

@test "migrates files from local Downloads to iCloud" {
  mkdir -p "$HOME/Downloads"
  echo "hello" > "$HOME/Downloads/hi.md"
  mkdir -p "$HOME/Downloads/subdir"
  echo "nested" > "$HOME/Downloads/subdir/deep.txt"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  local icloud="$HOME/$ICLOUD_REL/Downloads"
  [ -f "$icloud/hi.md" ]
  [ "$(cat "$icloud/hi.md")" = "hello" ]
  [ -f "$icloud/subdir/deep.txt" ]
  [ "$(cat "$icloud/subdir/deep.txt")" = "nested" ]
  [ -L "$HOME/Downloads" ]
}

@test ".DS_Store is silently dropped, not migrated" {
  mkdir -p "$HOME/Downloads"
  echo "junk" > "$HOME/Downloads/.DS_Store"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/$ICLOUD_REL/Downloads/.DS_Store" ]
  [ -L "$HOME/Downloads" ]
}

@test "name conflicts halt with status 1 and list the conflicts" {
  local icloud="$HOME/$ICLOUD_REL/Downloads"
  mkdir -p "$icloud"
  echo "iCloud version" > "$icloud/conflict.txt"
  mkdir -p "$HOME/Downloads"
  echo "local version" > "$HOME/Downloads/conflict.txt"

  run bash "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Name conflicts"* ]]
  [[ "$output" == *"conflict.txt"* ]]
  # Both copies preserved — no destructive merge.
  [ -f "$HOME/Downloads/conflict.txt" ]
  [ -f "$icloud/conflict.txt" ]
}

@test "--dry-run doesn't mutate the filesystem" {
  mkdir -p "$HOME/Downloads"
  echo "untouched" > "$HOME/Downloads/hi.md"

  run bash "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  # ~/Downloads is still a real directory with the file.
  [ -d "$HOME/Downloads" ]
  [ ! -L "$HOME/Downloads" ]
  [ -f "$HOME/Downloads/hi.md" ]
  [ "$(cat "$HOME/Downloads/hi.md")" = "untouched" ]
  # iCloud target was not created.
  [ ! -d "$HOME/$ICLOUD_REL/Downloads" ]
}

@test "non-Darwin uname skips entirely" {
  # Override our Darwin-mocking uname with a Linux one.
  cat > "$BATS_TEST_TMPDIR/bin/uname" <<'EOF'
#!/usr/bin/env bash
echo "Linux"
EOF
  mkdir -p "$HOME/Downloads"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skip (not Darwin)"* ]]
  # ~/Downloads untouched.
  [ -d "$HOME/Downloads" ]
  [ ! -L "$HOME/Downloads" ]
}
