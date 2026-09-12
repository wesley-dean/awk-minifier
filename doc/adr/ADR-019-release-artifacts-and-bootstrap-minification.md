# ADR-019: Release Artifacts and Bootstrap Minification

Date: 2026-09-12

## Status

Accepted

## Context

The repository inherits the template's useful three-artifact release model, but
its artifact names and production-minification mechanics are Bash-specific.  AWK
Minifier also has a bootstrapping problem: the intended production minified
artifact should eventually be produced by a previously released, known-good AWK
Minifier, yet no trustworthy AWK Minifier release exists before the first working
version is created.

Using the candidate build to create its own production artifact would make release
construction depend on the exact unproven code being released.  Omitting the
`.min.awk` artifact from early releases would avoid that trust cycle but would
change the release surface between bootstrap and normal releases.

## Decision Drivers

- Ship stable artifact names from the first usable release onward.
- Keep artifact provenance truthful during bootstrap.
- Never require the candidate transformer to create its own production artifact.
- Make the eventual transition to previous-release minification an internal build
  change rather than a public release-contract change.
- Keep all released artifacts checksummed and behavior-tested.

## Decision

Every normal release SHALL publish these standalone artifacts:

```text
dist/awk-minifier.dev.awk
dist/awk-minifier.awk
dist/awk-minifier.min.awk
```

Each artifact SHALL have an adjacent `.sha256` checksum companion.

`awk-minifier.dev.awk` SHALL be the deterministic assembly of maintained modules,
including source documentation and development-oriented comments that are part of
the assembled source.

`awk-minifier.awk` SHALL be the ordinary production artifact.  Its construction
MAY conservatively remove project-governed documentation or header material, but
its build step MUST NOT act as an independent general-purpose AWK parser whose
rewrites are less safe than the product itself.

### Bootstrap behavior

Until the repository pins a previously released AWK Minifier as the trusted build
transformer, `awk-minifier.min.awk` SHALL be an exact byte-for-byte copy of
`awk-minifier.dev.awk`.

This artifact name is a stable release slot during bootstrap; the repository SHALL
NOT claim that the bootstrap `.min.awk` bytes have actually been minified.
Documentation and build comments SHALL make that condition explicit.

### Steady-state behavior

After a trustworthy released version exists, that immutable release SHALL be
pinned through bashdeps as `vendor/awk-minifier.awk` using an immutable release URL
and committed SHA-256 digest.  Subsequent production `.min.awk` artifacts SHALL be
created by piping the current ordinary or designated production input through that
previously released transformer according to the Makefile's documented build
pipeline.

The current candidate version MUST NOT be used to create its own production
`.min.awk` release artifact.

Candidate self-minification MAY be exercised as a test-only dogfooding surface.
A self-minified candidate MUST NOT silently replace the trusted previous-release
transformer in the production build path.

All three shipped artifacts SHALL run the same public behavior suite.  Artifact
construction SHALL use temporary sibling files and atomic replacement so a failed
build does not publish a partial artifact as current output.

## Promises

1. Development, ordinary, and minified artifact names exist from the first usable
   release.
2. Bootstrap `.min.awk` equals `.dev.awk` byte-for-byte until a prior released
   transformer is pinned.
3. Production self-hosting never uses the current candidate as its own trust root.
4. Every artifact receives an adjacent `.sha256` companion.
5. All shipped artifacts satisfy the same observable transformer contract.

## Non-Promises

1. The bootstrap `.min.awk` filename does not promise smaller bytes.
2. Byte identity among artifact flavors is not guaranteed after steady-state
   minification begins.
3. Candidate self-minification success is not sufficient release provenance.
4. SHA-256 verification establishes expected bytes, not behavioral correctness.

## Considered Alternatives

### Publish Only Development and Ordinary Artifacts Initially

Rejected because it changes the release asset contract after bootstrap and creates
special-case consumer expectations.

### Create a Special Bootstrap-Seed Release

Rejected as unnecessary.  Copying `.dev.awk` into the stable `.min.awk` slot is
simpler, truthful, and avoids inventing a special release lineage solely to solve
the initial cycle.

### Self-Minify the First Release

Rejected because the candidate would become its own production build dependency
before it has an independently trusted release history.

### Keep the Bootstrap Copy Forever

Rejected because a previously released AWK Minifier provides a better eventual
production transformation path and validates the tool against real maintained
source.

## Consequences

The first working releases contain a `.min.awk` file whose bytes intentionally
match `.dev.awk`.  Consumers can nevertheless depend on stable filenames,
checksums, tests, and attestations.

A later change that pins the first trusted release will update the dependency
manifest and build recipe but will not rename release assets.  That transition is
consequential build provenance and should be recorded in an ADR update or a new
ADR when it occurs.

## Superseded Decisions

This ADR supersedes ADR-006's Bash-specific artifact filenames and Bash-Minifier
production pipeline while preserving the three-flavor, metadata, checksum, and
behavior-equivalence principles.

ADR-012's `.sha256` naming remains governing and is not superseded.

## Related Decisions

- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-011: Conventional-Commit Semantic Releases and Late Tagging
- ADR-012: Standardize SHA-256 Checksum Companion Filenames
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-018: Portable AWK Runtime and Explicit Source Assembly
