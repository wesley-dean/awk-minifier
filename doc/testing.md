# Testing

AWK Minifier uses a portable shell harness in `tests/run-tests.sh`.  The harness
is parameterized by `AWK_BIN` so the same behavior contract can be exercised
against multiple AWK implementations without rewriting fixtures.

Tests are evidence for documented behavior and accepted ADRs.  They do not replace
those architectural sources.

## Execution surfaces

The public behavior contract is exercised through:

- maintained modular source using repeated `awk -f` arguments;
- `dist/awk-minifier.dev.awk`;
- `dist/awk-minifier.awk`; and
- `dist/awk-minifier.min.awk`.

A build transformation is part of the product pipeline, so an artifact is not
assumed correct merely because maintained source passed tests.

## Required evidence

Changes to transformation behavior should use focused fixtures that cover both
exact output and semantic equivalence where practical.  Important classes include:

- comments adjacent to tokens;
- `#` inside strings and regexp literals;
- escaped quotes and escaped regexp delimiters;
- division, chained division, and `/=`;
- regexp pattern rules and match operators;
- horizontal whitespace and indentation;
- physical newlines and backslash continuations;
- control-header newlines after `if`, `for`, and ordinary `while`;
- `do ... while` trailers, including nested loops;
- function-definition header line breaks;
- grammar-optional newlines after `{`, comma, `&&`, `||`, `do`, and `else`;
- top-level rule separation after physical newline removal;
- malformed strings and regexp literals;
- first-line shebang handling; and
- idempotence of the transformation.

Malformed-input tests must assert both a nonzero exit status and empty STDOUT.
This protects the buffered-output contract: an error must not expose a partial
transformation that a caller could mistake for success.

## Physical-line invariant

ADR-023 makes output line count part of the observable representation contract.
Successful transformed source must contain:

- exactly one physical newline when a first-line shebang is preserved; or
- zero physical newlines when there is no shebang.

Tests should count newline bytes directly rather than infer the property from
`wc -l`, because a non-newline-terminated one-line body is intentional output.
The final source newline is discarded when EOF already terminates the final
statement or rule.

A significant source newline that remains grammatically necessary must become a
semicolon.  Grammar-optional newlines disappear.  Tests should therefore assert
both byte-level shape and program behavior for control flow, rule boundaries, and
continuations.

## Semantic comparisons

For valid fixtures whose exact output bytes are not the whole contract, execute
both the original and transformed AWK program against the same input and compare
their observable output.  This is especially important for slash classification
and newline-sensitive syntax, where a visually plausible transformation can still
change meaning.

## Candidate self-minification

The current modular transformer may minify the current development artifact as a
test-only exercise.  This proves that the maintained implementation itself
satisfies ADR-023's shebang-plus-one-program-line target and that the resulting
source remains executable AWK.

Candidate self-minification is not production build provenance.  ADR-022 still
requires production `.min.awk` construction to use the pinned previous release.
Tests must keep those two concerns distinct.

## Portability

CI exercises the suite under GNU awk, mawk, BusyBox awk, and the macOS system AWK
where practical.  `AWK_BIN` is an executable path or command name, not a shell
fragment; wrappers such as BusyBox should therefore be exposed through an `awk`
symlink when needed.

A portability failure is a product failure unless repository governance explicitly
allows the implementation-specific behavior.

## Build evidence

`make build` must remain network-free and must not acquire or repair repository
dependencies.  Steady-state minification requires prepared
`vendor/awk-minifier.awk` state, so CI first verifies that a fresh `make build`
fails without creating `vendor/`, then prepares dependencies through `make deps`
and performs the build.

The build must produce exactly three executable `.awk` release artifacts with
adjacent `.sha256` companions.  The development, ordinary, and minified artifacts
must identify their representation accurately in the generated header.  The
ordinary artifact removes project-governed Doxygen lines, while the minified
artifact body must exactly match the output of the pinned AWK Minifier v0.1.0 when
it transforms the ordinary artifact body.

The minified artifact retains a build-owned provenance header outside the
transformer input.  CI therefore compares artifact bodies after the
`# End generated header.` marker rather than comparing the complete minified file
to the raw transformer output.

The production `.min.awk` file may still contain many physical source lines while
v0.1.0 remains the pinned production transformer.  That representation is not a
failure of ADR-023: the release artifact contains the current transformer code,
and its behavior must satisfy the new output-line contract when executed.  A later
release can advance the production trust anchor after the improved transformer is
itself released and trusted.

Repeated builds with the same source, version, commit, commit-derived build date,
prepared dependency bytes, and AWK implementation must produce identical artifact
and checksum bytes.  CI removes the first `dist/` tree and performs a fresh second
build before comparing bytes.

## Dependency and documentation evidence

`make deps` is the explicit network-capable path for repository tools;
`make deps-check` verifies prepared state offline.  The tool verification includes
the pinned v0.1.0 AWK Minifier that participates in production artifact
construction.  `make standards` and `make standards-check` provide the equivalent
separate lifecycle for synchronized shared standards.

`make docs` consumes prepared `awk-doxygen` and `adrctl` state without acquiring
or repairing dependencies.  CI verifies generated ADR navigation and Doxygen HTML
while confirming those products remain ignored generated state.
