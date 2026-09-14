# AGENTS.md

## Purpose

AWK Minifier is a conservative AWK source-to-source transformer.  Maintained
product code is portable AWK; Bash is repository orchestration only.

Before changing behavior, read `README.md`, `doc/decisions.md`, the applicable
ADRs under `doc/adr/`, and the committed standards under `doc/standards/`.
Accepted ADRs and applicable standards under `doc/standards/` are governance, not
suggestions.

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
src/context.awk
src/lexer.awk
src/transform.awk
src/main.awk
```

The modular source must remain directly executable with repeated `awk -f`
arguments in that order.  Do not replace explicit ordering with filesystem glob
ordering or runtime plugin discovery.

Maintained AWK source follows the committed AWK documentation standard from
`coding_standards`.  Use `##` Doxygen blocks for maintained interfaces and
ordinary `#` comments for narrow implementation notes.

## Transformation safety

Treat comments, strings, regexp literals, division, `/=`, continuations, and
newline-sensitive grammar as lexical/contextual concerns.  Do not implement new
rewrites as blind regular-expression substitutions over raw lines.

ADR-023 governs physical newline elimination.  For successful portable-AWK input,
transformed source contains exactly one physical newline when a first-line shebang
is preserved and zero otherwise.  Grammar-optional newlines disappear; remaining
statement and rule terminators become semicolons.  Explicit backslash-newline
continuation between source tokens disappears without becoming a statement
boundary.

Backslash-newline inside a string or regexp literal is outside the accepted
portable input contract because the supported AWK implementations do not agree on
its observable semantics.  Reject that source with nonzero status and no partial
STDOUT rather than normalizing it according to one implementation.

Do not treat all newlines alike.  In particular, preserve structural recognition
of `if`, `for`, ordinary `while`, function-definition headers, `do ... while`
trailers, braces, commas, logical continuations, `do`, and `else`.  Any change to
newline classification must add both focused byte-level evidence and semantic
comparisons.

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

AWK Minifier v0.2.1 is the pinned previous-release production transformer.
Bashdeps synchronizes it as `vendor/awk-minifier.awk`, and the build applies it to
the body of the current ordinary artifact to create `.min.awk`.  The generated
provenance header is kept outside the transformer input and regenerated for the
minified artifact so version, build date, build commit, and minifier identity
remain inspectable.

The current candidate must never be used to create its own production `.min.awk`
release artifact.  Candidate self-minification is permitted only as test evidence,
including the ADR-023 assertion that the maintained development artifact collapses
to a shebang plus one program line.

Do not silently fall back to copying `.dev.awk`, to self-minification, or to
another transformer when the pinned dependency is missing or fails.

`make build` must remain network-free and must not invoke dependency acquisition or
standards updates implicitly.  Steady-state builds require prepared
`vendor/awk-minifier.awk` state; use `make deps` or `make all` before `make build`.

## Dependencies and standards

Make directly bootstraps only `vendor/bashdeps.bash`, using the pinned version and
SHA-256 digest in the Makefile.  Other executable repository tools belong in
`dependencies.txt`, including the pinned previous-release AWK Minifier used by the
production build.

Network boundaries:

- `make deps` may access the network and repair executable tool dependency state;
- `make deps-check` is offline and non-repairing; and
- `make build`, `make test`, and `make docs` do not hide dependency acquisition.

The complete shared standards snapshot from `wesley-dean/coding_standards` is
committed beneath `doc/standards/`.  `.codingstandardrc` records the concrete
released version, release-archive SHA-256 digest, canonical source repository, and
managed destination.  The repository contains no standards-fetching workflow,
Make synchronization target, or standards dependency manifest.  Agents should use
the committed files directly.

For this repository, the general standards and AWK standards apply.  Repository,
Markdown, ADR, Bash, or other shared standards also apply when their subject matter
is present and relevant to the change.  Language-specific standards for unrelated
implementation languages do not become applicable merely because the complete
library is present.  Content beneath `examples/` is illustrative and non-normative
unless a governing standard states otherwise.

Apply every relevant standard unless an accepted repository-specific ADR or
explicit repository policy supersedes or refines it.  Do not silently deviate from
an applicable standard.  Do not edit imported shared standards locally to encode a
project-specific exception; document the exception through repository governance.

Shared-standard changes belong in the canonical `wesley-dean/coding_standards`
repository.  A standards refresh selects a concrete released version, replaces the
complete managed `doc/standards/` tree, updates `.codingstandardrc`, and is proposed
through a normal pull request against the default branch.

## Tests

The primary harness is `tests/run-tests.sh` and is parameterized by `AWK_BIN`.
Every public behavior suite should cover:

- modular repeated-`-f` source;
- the development artifact;
- the ordinary artifact; and
- the minified artifact.

Add regression fixtures for every confirmed semantic bug.  Prefer semantic
comparisons in addition to exact golden text where the exact byte representation
is not itself the contract.  Malformed or rejected non-portable-input tests must
verify both nonzero status and absence of partial STDOUT.

Portability testing should include GNU awk, mawk, BusyBox awk, and original awk.
A BSD/macOS AWK implementation remains useful supplemental evidence where a runner
or local system makes that practical, but it is not required as a hosted CI gate.

Newline tests must include physical-line counts, statement and rule separation,
control headers, nested conditionals, ordinary and `do ... while` loops,
function-definition line breaks, portable explicit continuation between tokens,
rejection of literal-internal backslash-newline, comments around optional newlines,
idempotence, and candidate self-minification.

Build-pipeline tests must also verify the previous-release lineage: the minified
artifact body must match the output of the pinned `vendor/awk-minifier.awk` when
that transformer receives the ordinary artifact body.

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
