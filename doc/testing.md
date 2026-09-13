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
- physical newlines and portable backslash continuation between tokens;
- rejection of backslash-newline inside string and regexp literals;
- control-header newlines after `if`, `for`, and ordinary `while`;
- `do ... while` trailers, including nested loops;
- function-definition header line breaks;
- grammar-optional newlines after `{`, comma, `&&`, `||`, `do`, and `else`;
- top-level rule separation after physical newline removal;
- malformed strings and regexp literals;
- first-line shebang handling; and
- idempotence of the transformation.

Malformed or explicitly rejected non-portable-input tests must assert both a
nonzero exit status and empty STDOUT.  This protects the buffered-output contract:
an error must not expose a partial transformation that a caller could mistake for
success.

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
portable continuations.

## Continuation portability

Backslash-newline between source tokens is part of the accepted portable contract
and is removed without creating a statement boundary.  Its tests compare both
exact output and original/transformed behavior.

Backslash-newline inside a string or regexp literal is different.  Portability
validation found that supported AWK implementations do not agree on the observable
semantics of that source construct.  The transformer therefore rejects it rather
than selecting one implementation's interpretation.  Tests must verify nonzero
status, the dedicated portability diagnostic, and empty STDOUT on every supported
AWK implementation.

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

Candidate self-minification is not production build provenance.  ADR-024 requires
production `.min.awk` construction to use the pinned v0.2.1 previous release.
Tests must keep those two concerns distinct.

## Portability

CI exercises the suite under GNU awk, mawk, BusyBox awk, and original awk on the
Ubuntu runner.  `AWK_BIN` is an executable path or command name, not a shell
fragment; wrappers such as BusyBox should therefore be exposed through an `awk`
symlink when needed.

A BSD/macOS AWK implementation remains useful supplemental evidence where a runner
or local system makes that practical, but it is not a required hosted CI gate.
This preserves diverse interpreter coverage without making release progress depend
on scarce macOS runner capacity.

A portability failure is a product failure unless repository governance explicitly
allows the implementation-specific behavior.  When supported implementations
disagree on source semantics, the portable transformer should fail closed rather
than silently choose one interpretation.

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
artifact body must exactly match the output of the pinned AWK Minifier v0.2.1 when
it transforms the ordinary artifact body.

The minified artifact retains a build-owned provenance header outside the
transformer input.  CI therefore compares artifact bodies after the
`# End generated header.` marker rather than comparing the complete minified file
to the raw transformer output.

Because v0.2.1 implements ADR-023's grammar-aware newline elimination, production
`.min.awk` bodies are expected to contain zero physical newlines.  The generated
provenance header remains intentionally multiline and outside the transformation
surface.

Repeated builds with the same source, version, commit, commit-derived build date,
prepared dependency bytes, and AWK implementation must produce identical artifact
and checksum bytes.  CI removes the first `dist/` tree and performs a fresh second
build before comparing bytes.

## Dependency and documentation evidence

`make deps` is the explicit network-capable path for executable repository tools;
`make deps-check` verifies prepared state offline.  The tool verification includes
the pinned v0.2.1 AWK Minifier that participates in production artifact
construction.

Shared coding standards use the separate ADR-025 lifecycle.  The manually
dispatched `Update Coding Standards` workflow resolves a released standards
archive, populates and validates `.codingstandardrc`, verifies the archive digest,
and materializes `doc/standards/`.  The proof-of-concept workflow currently ends by
printing the resulting documentation tree with `find doc/ -print`; it does not yet
commit or push the materialized files.

Once the workflow's persistence path is enabled, CI should treat
`.codingstandardrc` and `doc/standards/` as tracked repository inputs rather than
calling a network synchronization target during ordinary product tests.

`make docs` consumes prepared `awk-doxygen` and `adrctl` state without acquiring
or repairing dependencies.  CI verifies generated ADR navigation and Doxygen HTML
while confirming those products remain ignored generated state.
