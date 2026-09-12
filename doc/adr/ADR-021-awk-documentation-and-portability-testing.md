# ADR-021: AWK Documentation and Portability Testing

Date: 2026-09-12

## Status

Accepted

## Context

The inherited template documents Bash with bash-doxygen and tests Bash artifacts
primarily with Bats.  AWK Minifier needs a different evidence model.  Its most
important risks are semantic transformation errors, interpreter portability,
ambiguous lexical context, and divergence among modular source and assembled
artifacts.

The shared `coding_standards` repository defines the AWK documentation convention,
and the awk-doxygen project provides the corresponding Doxygen input filter.  The
awk-doxygen repository also demonstrates a lightweight shell harness parameterized
by `AWK_BIN`, which is a better fit for running the same corpus against multiple
AWK implementations than retaining Bats as the product's primary behavior layer.

## Decision Drivers

- Source documentation should follow the shared AWK standard rather than inherited
  Bash conventions.
- Product tests must run under multiple AWK implementations.
- Every shipped artifact flavor must prove the same behavior.
- Tests must catch semantic changes, not merely textual differences.
- Ambiguous or malformed inputs need explicit negative evidence.
- Documentation generation remains offline after dependencies are prepared.

## Decision

Maintained AWK source SHALL follow the imported AWK documentation standard from
`coding_standards`.  Doxygen reference generation SHALL use the pinned
`awk-doxygen` filter prepared through bashdeps.

The product's primary test harness SHALL be shell-based and SHALL support selecting
the interpreter through `AWK_BIN`.  The harness SHALL exercise, at minimum:

- maintained modular source invoked through repeated `awk -f` arguments;
- `dist/awk-minifier.dev.awk`;
- `dist/awk-minifier.awk`; and
- `dist/awk-minifier.min.awk`.

The core corpus SHALL combine several evidence types:

1. golden transformations for exact expected output where exactness is part of the
   contract;
2. semantic equivalence tests that run original and transformed AWK against the
   same fixtures and compare observable output/status;
3. negative tests for malformed, unsupported, or unsafe-to-transform input;
4. focused lexical/context fixtures for strings, escapes, comments, regexp
   literals, division, assignment operators, continuations, and newline-sensitive
   constructs;
5. idempotence checks where `minify(minify(source))` is expected to equal
   `minify(source)` without weakening safety to obtain the property;
6. deterministic fuzz or generated-corpus cases where practical; and
7. regression fixtures for every confirmed semantic bug.

Candidate self-minification SHALL be test-only.  The harness MAY minify the current
candidate with itself and execute the result as dogfooding evidence, but this test
surface does not alter ADR-019's production provenance rule.

CI SHOULD exercise multiple interpreters, including GNU awk and mawk, and SHOULD
add BusyBox awk and a BSD/macOS AWK implementation where the runner makes that
practical.  Additional One True Awk/nawk coverage is encouraged when it can be
installed reproducibly.

`make docs` SHALL consume already-prepared `awk-doxygen` and `adrctl` artifacts,
generate the ephemeral ADR landing page, and invoke Doxygen without synchronizing
dependencies.  Generated reference documentation remains ignored state.

A post-release canary SHOULD download the exact published AWK artifacts and their
checksums, verify those bytes, and execute smoke/behavior tests against the release
assets rather than substituting a tag checkout.

## Promises

1. Maintained AWK source follows the shared AWK documentation standard.
2. AWK source documentation is processed by awk-doxygen, not bash-doxygen.
3. The same public behavior suite covers modular source and all release artifacts.
4. Interpreter selection is explicit through `AWK_BIN`.
5. Semantic equivalence and adversarial lexical cases are first-class evidence.
6. Documentation generation stays offline after dependency preparation.

## Non-Promises

1. Passing one AWK implementation does not establish portability.
2. Golden text equality alone does not establish semantic preservation.
3. Self-minification success does not authorize candidate self-hosting for release
   construction.
4. Generated documentation is not maintained architectural source.

## Considered Alternatives

### Keep Bats as the Primary Product Harness

Rejected as the primary layer because the central matrix dimension is the AWK
interpreter and the tests are naturally expressed as source/fixture/output
comparisons.  Bats may still be used for repository-level shell orchestration if a
specific test benefits from it.

### Test Only the Development Artifact

Rejected because assembly, ordinary-artifact processing, bootstrap copying, and
future previous-release minification can each introduce divergence.

### Test Only Exact Minified Text

Rejected because many safe textual outputs may be semantically equivalent while a
plausible-looking exact output can still change behavior on a fixture not
represented by that golden case.

### Use gawk-Only Tests

Rejected because GNU extensions or implementation-specific behavior could enter
the code unnoticed and violate the portable AWK baseline.

## Consequences

The existing Bats product tests and bash-doxygen configuration will be replaced or
reduced to only those repository-level concerns that still apply.  Test fixture
volume grows substantially because safety depends on covering lexical and grammar
boundaries explicitly.

CI takes longer than a single-interpreter smoke suite, but failures provide much
stronger evidence about the product's actual portability and semantic contract.

## Superseded Decisions

This ADR supersedes ADR-007's Bash-specific source documentation standard with the
shared AWK documentation standard and awk-doxygen filter.

This ADR supersedes ADR-009's requirement that Bats be the default product behavior
framework while preserving its stronger invariant that every shipped artifact
receives the same observable behavior suite.

This ADR refines ADR-010 and ADR-017 by replacing the Bash source-code filter with
awk-doxygen while preserving ephemeral generated documentation and offline ADR
navigation generation.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-007: Doxygen-Based Verbose Source Documentation Standard
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-017: Generate ADR Navigation Ephemerally
- ADR-018: Portable AWK Runtime and Explicit Source Assembly
- ADR-019: Release Artifacts and Bootstrap Minification
- ADR-020: Bashdeps-Managed Tools and Standards
