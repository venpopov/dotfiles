# bats helper — per-test isolated $HOME.
#
# Usage in a .bats file:
#   load '../helpers/setup'
#   setup()    { setup_test_home; }
#   teardown() { teardown_test_home; }
#
# Each test gets a fresh $HOME under $BATS_TEST_TMPDIR, which bats auto-cleans.

setup_test_home() {
  TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"
  export HOME="$TEST_HOME"
}

teardown_test_home() {
  # BATS_TEST_TMPDIR is auto-cleaned by bats; nothing more to do here yet.
  :
}
