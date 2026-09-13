# Test Fixtures

`tests/run-tests.sh` is a TAP 14 producer.  It discovers AWK inputs under
`tests/fixtures/` in lexical order and uses the fixture basename as the TAP test
name.

Fixture names begin with a two-digit sequence followed by a short description of
the behavior under test, for example:

```text
tests/fixtures/01-simple-function.awk
tests/fixtures/07-control-flow-newlines.awk
```

Every fixture must have exactly one matching expectation under `tests/expected/`:

- `<name>.awk` means transformation must succeed and produce those exact bytes;
- `<name>.stderr` means transformation must fail, publish no STDOUT, and emit
  exactly that diagnostic on STDERR.

For successful fixtures, the runner additionally verifies idempotence and executes
both the original fixture and expected transformed program on empty input to catch
observable semantic differences.

The runner also checks that expected-result files are not orphaned, exercises all
three assembled release artifacts against a representative fixture, and performs
test-only candidate self-minification.

Typical output is standard TAP:

```text
TAP version 14
# AWK_BIN: mawk
ok 1 - 01-simple-function
ok 2 - 02-shebang-comments
not ok 3 - 03-semantic-rules
# transformed bytes differ from expected output
1..3
```

A failed TAP test also causes `tests/run-tests.sh` to exit nonzero after the final
plan line.  Setup failures that make further testing meaningless use TAP's
`Bail out!` form.
