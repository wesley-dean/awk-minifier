# AGENTS.md

## Purpose

AWK Minifier is a conservative AWK source-to-source transformer.  Maintained
product code is portable AWK; Bash is repository orchestration only.

Before changing behavior, read `README.md`, `doc/decisions.md`, the applicable
ADRs under `doc/adr/`, and synchronized standards under `doc/standards/` when they
are present.  Accepted ADRs are governance, not suggestions.

## Product contract

- Read AWK source from STDIN.
- Write transformed AWK source to STDOUT.
- Write diagnostics to STDERR.
- Exit zero only after the complete source has been transformed successfully.
- Do not publish partial transformed output after a transformation failure.
- Favor semantic preservation over smaller output.
- Do not require GNU AWK extensions without a governing ADR.

## Maintained source

The Makefile owns the exact source order.  Maintained modules currently are:

```text
src/diagnostics.awk
src/output.awk
src/lexer.awk
src/main.awk
```

The modular source must remain directly executable with repeated `awk -f`
arguments in that order.  Do not replace explicit ordering with filesystem glob
ordering or runtime plugin discovery.

Maintained AWK source follows the synchronized AWK documentation standard from
`coding_standards`.  Use `##` Doxygen blocks for maintained interfaces and
ordinary `#` comments for narrow implementation notes.

## Transformation safety

Treat comments, strings, regexp literals, division, `/=`, continuations, and
newline-sensitive grammar as lexical/contextual concerns.  Do not implement new
rewrites as blind regular-expression substitutions over raw lines.

Physical newlines are deliberately preserved by the first implementation.  A
future optimization that removes or rewrites newlines is consequential behavior
and must be justified with stronger grammar evidence and tests.

Slash interpretation is contextual.  A slash is not inherently a regexp delimiter
or a division operator.  Any change to slash classification must add focused
regression and semantic-equivalence fixtures.

Output is buffered until validation completes.  Preserve this no-partial-success
property when changing the pipeline.

## Build products

`make build` creates:

```text
dist/awk-minifier.dev.awk
dist/awk-minifier.awk
dist/awk-minifier.min.awk
```

with adjacent `.sha256` companions.

During bootstrap, `.min.awk` must be byte-for-byte identical to `.dev.awk`.  Do
not use the current candidate to create its own production minified artifact.
After a trustworthy release exists, a separately governed change may pin that
release through Bashdeps and use it as the transformer for later releases.

`make build` must remain network-free and must not invoke dependency or standards
synchronization implicitly.

## Dependencies and standards

Make directly bootstraps only `vendor/bashdeps.bash`, using the pinned version and
SHA-256 digest in the Makefile.  Other repository tools belong in
`dependencies.txt`.

Network boundaries:

- `make deps` may access the network and repair tool dependency state;
- `make deps-check` is offline and non-repairing;
- `make standards` may access the network and synchronize shared standards;
- `make standards-check` is offline and non-repairing;
- `make build`, `make test`, and `make docs` do not hide dependency acquisition.

Shared standards come from `wesley-dean/coding_standards` through
`dependencies-standards.txt`.  Do not edit synchronized copies under
`doc/standards/`; change the upstream standard, update the immutable pin/digest,
and resynchronize instead.

## Tests

The primary harness is `tests/run-tests.sh` and is parameterized by `AWK_BIN`.
Every public behavior suite should cover:

- modular repeated-`-f` source;
- the development artifact;
- the ordinary artifact; and
- the minified artifact.

Add regression fixtures for every confirmed semantic bug.  Prefer semantic
comparisons in addition to exact golden text where the exact byte representation
is not itself the contract.  Malformed-input tests must verify both nonzero status
and absence of partial STDOUT.

Portability testing should include at least GNU awk and mawk, with BusyBox awk and
a BSD/macOS AWK implementation where practical.

## Documentation

`make docs` consumes prepared `vendor/doxygen-awk.awk` and `vendor/adrctl.bash`
without acquiring dependencies.  Generated `doc/adr/README.md` and
`doc/reference/` output are ephemeral and ignored.

`doc/decisions.md` remains the always-present architectural discovery surface.
When adding or materially changing an ADR, update `doc/decisions.md` in the same
change.

## Scope discipline

Keep changes surgical.  Do not introduce runtime extension machinery,
implementation-specific AWK features, unrelated cleanup, or architectural
abstractions merely because they may be useful elsewhere.  When an ambiguity does
not materially affect correctness, security, compatibility, architecture, or a
public contract, prefer the smallest decision consistent with existing governance.
