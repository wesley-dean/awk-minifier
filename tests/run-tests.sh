#!/bin/sh
set -u

AWK_BIN=${AWK_BIN:-awk}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FIXTURE_DIR="$ROOT/tests/fixtures"
EXPECTED_DIR="$ROOT/tests/expected"
TMP=${TMPDIR:-/tmp}/awk-minifier-tests.$$
MODULAR="$AWK_BIN -f $ROOT/src/diagnostics.awk -f $ROOT/src/output.awk -f $ROOT/src/context.awk -f $ROOT/src/lexer.awk -f $ROOT/src/transform.awk -f $ROOT/src/main.awk"

export LC_ALL=C

test_number=0
failure_count=0

bail_out() {
  printf 'Bail out! %s\n' "$1"
  exit 1
}

tap_ok() {
  test_number=$((test_number + 1))
  printf 'ok %d - %s\n' "$test_number" "$1"
}

tap_not_ok() {
  test_number=$((test_number + 1))
  failure_count=$((failure_count + 1))
  printf 'not ok %d - %s\n' "$test_number" "$1"
}

tap_skip() {
  test_number=$((test_number + 1))
  printf 'ok %d - %s # SKIP %s\n' "$test_number" "$1" "$2"
}

tap_diag() {
  printf '# %s\n' "$1"
}

tap_diff() {
  diff -u "$1" "$2" 2>&1 | sed 's/^/# /'
}

run_modular() {
  # shellcheck disable=SC2086
  $MODULAR
}

newline_count() {
  tr -cd '\n' <"$1" | wc -c | tr -d '[:space:]'
}

fixture_failure() {
  name=$1
  message=$2
  tap_not_ok "$name"
  tap_diag "$message"
}

run_success_fixture() {
  fixture=$1
  expected=$2
  name=$3
  actual="$TMP/$name.actual"
  stderr_file="$TMP/$name.stderr"
  twice="$TMP/$name.twice"
  twice_stderr="$TMP/$name.twice.stderr"
  original_out="$TMP/$name.original.out"
  original_err="$TMP/$name.original.err"
  expected_out="$TMP/$name.expected.out"
  expected_err="$TMP/$name.expected.err"

  status=0
  if run_modular <"$fixture" >"$actual" 2>"$stderr_file"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne 0 ]; then
    fixture_failure "$name" "transformer exited with status $status"
    [ ! -s "$stderr_file" ] || sed 's/^/# stderr: /' "$stderr_file"
    return
  fi

  if [ -s "$stderr_file" ]; then
    fixture_failure "$name" 'successful transformation wrote to STDERR'
    sed 's/^/# stderr: /' "$stderr_file"
    return
  fi

  if ! cmp -s "$expected" "$actual"; then
    fixture_failure "$name" 'transformed bytes differ from expected output'
    tap_diff "$expected" "$actual"
    return
  fi

  status=0
  if run_modular <"$expected" >"$twice" 2>"$twice_stderr"; then
    status=0
  else
    status=$?
  fi
  if [ "$status" -ne 0 ] || [ -s "$twice_stderr" ] || ! cmp -s "$expected" "$twice"; then
    fixture_failure "$name" 'expected output is not idempotent under the transformer'
    [ ! -s "$twice_stderr" ] || sed 's/^/# stderr: /' "$twice_stderr"
    cmp -s "$expected" "$twice" || tap_diff "$expected" "$twice"
    return
  fi

  original_status=0
  if "$AWK_BIN" -f "$fixture" </dev/null >"$original_out" 2>"$original_err"; then
    original_status=0
  else
    original_status=$?
  fi
  expected_status=0
  if "$AWK_BIN" -f "$expected" </dev/null >"$expected_out" 2>"$expected_err"; then
    expected_status=0
  else
    expected_status=$?
  fi

  if [ "$original_status" -ne "$expected_status" ] ||
     ! cmp -s "$original_out" "$expected_out" ||
     ! cmp -s "$original_err" "$expected_err"; then
    fixture_failure "$name" 'original and transformed programs are not semantically equivalent on empty input'
    tap_diag "original exit: $original_status; transformed exit: $expected_status"
    if ! cmp -s "$original_out" "$expected_out"; then
      tap_diag 'STDOUT differs:'
      tap_diff "$original_out" "$expected_out"
    fi
    if ! cmp -s "$original_err" "$expected_err"; then
      tap_diag 'STDERR differs:'
      tap_diff "$original_err" "$expected_err"
    fi
    return
  fi

  tap_ok "$name"
}

run_failure_fixture() {
  fixture=$1
  expected_stderr=$2
  name=$3
  actual_stdout="$TMP/$name.stdout"
  actual_stderr="$TMP/$name.stderr"

  status=0
  if run_modular <"$fixture" >"$actual_stdout" 2>"$actual_stderr"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -eq 0 ]; then
    fixture_failure "$name" 'fixture was expected to be rejected but transformation succeeded'
    return
  fi

  if [ -s "$actual_stdout" ]; then
    fixture_failure "$name" 'rejected fixture published partial STDOUT'
    sed 's/^/# stdout: /' "$actual_stdout"
    return
  fi

  if ! cmp -s "$expected_stderr" "$actual_stderr"; then
    fixture_failure "$name" 'diagnostic differs from expected STDERR'
    tap_diff "$expected_stderr" "$actual_stderr"
    return
  fi

  tap_ok "$name"
}

run_fixture() {
  fixture=$1
  filename=${fixture##*/}
  name=${filename%.awk}
  expected_stdout="$EXPECTED_DIR/$name.awk"
  expected_stderr="$EXPECTED_DIR/$name.stderr"

  if [ -f "$expected_stdout" ] && [ -f "$expected_stderr" ]; then
    fixture_failure "$name" 'fixture has both .awk and .stderr expectations'
    return
  fi

  if [ -f "$expected_stdout" ]; then
    run_success_fixture "$fixture" "$expected_stdout" "$name"
    return
  fi

  if [ -f "$expected_stderr" ]; then
    run_failure_fixture "$fixture" "$expected_stderr" "$name"
    return
  fi

  fixture_failure "$name" 'fixture has no matching expected result'
}

check_expected_corpus() {
  ok=1
  for expected in "$EXPECTED_DIR"/*.awk "$EXPECTED_DIR"/*.stderr; do
    [ -e "$expected" ] || continue
    filename=${expected##*/}
    name=${filename%.awk}
    name=${name%.stderr}
    if [ ! -f "$FIXTURE_DIR/$name.awk" ]; then
      ok=0
      tap_diag "orphan expectation: ${expected#$ROOT/}"
    fi
  done

  if [ "$ok" -eq 1 ]; then
    tap_ok 'fixture-corpus-integrity'
  else
    tap_not_ok 'fixture-corpus-integrity'
  fi
}

run_artifact_test() {
  artifact=$1
  fixture="$FIXTURE_DIR/02-shebang-comments.awk"
  expected="$EXPECTED_DIR/02-shebang-comments.awk"
  name="artifact-${artifact##*/}"
  actual="$TMP/$name.actual"
  stderr_file="$TMP/$name.stderr"

  if [ ! -f "$artifact" ]; then
    tap_skip "$name" 'artifact not present'
    return
  fi

  status=0
  if "$AWK_BIN" -f "$artifact" <"$fixture" >"$actual" 2>"$stderr_file"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne 0 ] || [ -s "$stderr_file" ] || ! cmp -s "$expected" "$actual"; then
    tap_not_ok "$name"
    tap_diag "artifact transformation failed or differed from expected output (status $status)"
    [ ! -s "$stderr_file" ] || sed 's/^/# stderr: /' "$stderr_file"
    cmp -s "$expected" "$actual" || tap_diff "$expected" "$actual"
    return
  fi

  tap_ok "$name"
}

run_self_minification_test() {
  source="$ROOT/dist/awk-minifier.dev.awk"
  name='candidate-self-minification'
  actual="$TMP/self.min.awk"
  stderr_file="$TMP/self.stderr"

  if [ ! -f "$source" ]; then
    tap_skip "$name" 'development artifact not present'
    return
  fi

  status=0
  if run_modular <"$source" >"$actual" 2>"$stderr_file"; then
    status=0
  else
    status=$?
  fi

  if [ "$status" -ne 0 ] || [ -s "$stderr_file" ]; then
    tap_not_ok "$name"
    tap_diag "self-minification failed with status $status"
    [ ! -s "$stderr_file" ] || sed 's/^/# stderr: /' "$stderr_file"
    return
  fi

  if [ "$(newline_count "$actual")" -ne 1 ]; then
    tap_not_ok "$name"
    tap_diag 'self-minified artifact did not contain exactly one shebang newline'
    return
  fi

  if ! "$AWK_BIN" -f "$actual" </dev/null >/dev/null 2>"$TMP/self-exec.stderr"; then
    tap_not_ok "$name"
    tap_diag 'self-minified artifact is not executable AWK'
    sed 's/^/# stderr: /' "$TMP/self-exec.stderr"
    return
  fi

  tap_ok "$name"
}

printf 'TAP version 14\n'
printf '# AWK_BIN: %s\n' "$AWK_BIN"

mkdir -p "$TMP" || bail_out 'unable to create temporary test directory'
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

[ -d "$FIXTURE_DIR" ] || bail_out 'missing tests/fixtures directory'
[ -d "$EXPECTED_DIR" ] || bail_out 'missing tests/expected directory'

set -- "$FIXTURE_DIR"/*.awk
[ -e "$1" ] || bail_out 'no AWK fixtures found'

for fixture do
  run_fixture "$fixture"
done

check_expected_corpus

run_artifact_test "$ROOT/dist/awk-minifier.dev.awk"
run_artifact_test "$ROOT/dist/awk-minifier.awk"
run_artifact_test "$ROOT/dist/awk-minifier.min.awk"
run_self_minification_test

printf '1..%d\n' "$test_number"

[ "$failure_count" -eq 0 ]
