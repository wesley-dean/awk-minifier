# ADR-022: Pin v0.1.0 as the Production Minification Transformer

Date: 2026-09-12

## Status

Accepted

## Context

ADR-019 established a deliberate bootstrap rule for the first usable AWK Minifier
release: until a trustworthy previous release existed, the stable
`awk-minifier.min.awk` release slot was an exact copy of the development artifact.
It also defined the steady-state transition: once a trusted release existed, that
release would be pinned through Bashdeps and used to produce later production
minified artifacts.

Version v0.1.0 has now completed that bootstrap cycle.  The release was produced
from reviewed source, passed the repository behavior and portability checks, and
published the three governed artifact flavors and checksum companions.  Its
ordinary `awk-minifier.awk` artifact is therefore available as the first
independent previous-release transformer.

The v0.1.0 transformer removes ordinary comments by design.  Current generated
build metadata is represented as comments at the start of each artifact.  Piping
the complete ordinary artifact through v0.1.0 would therefore remove the
human-inspectable version, build date, and build commit metadata that the
three-artifact model intends to preserve.

## Decision Drivers

- Complete the bootstrap transition defined by ADR-019.
- Use a reviewed previous release rather than the current candidate as the
  production trust root.
- Keep dependency acquisition explicit, pinned, and independently verifiable.
- Preserve a network-free `make build` after dependency preparation.
- Preserve human-inspectable build provenance in every shipped artifact.
- Make previous-release lineage directly testable in CI.
- Fail closed when the required transformer is missing or fails.

## Decision

AWK Minifier v0.1.0 SHALL be the production transformer for subsequent
`.min.awk` builds until another accepted decision changes that pin.

The following v0.1.0 release asset SHALL be declared in `dependencies.txt`:

```text
id=wesley-dean/awk-minifier@0.1.0
url=https://github.com/wesley-dean/awk-minifier/releases/download/v0.1.0/awk-minifier.awk
dest=vendor/awk-minifier.awk
digest=sha256:78dad61b927c2fe96c0e6ddfef75dd1cf395e5572a3e7a54f73622bd29bd58b6
```

The manifest entry remains one physical line in the actual Bashdeps manifest.

`make deps` MAY acquire the pinned release artifact.  `make deps-check` SHALL
verify the prepared bytes offline.  `make build` SHALL NOT acquire or repair the
dependency and SHALL fail with an actionable diagnostic when
`vendor/awk-minifier.awk` is absent.

### Minified artifact construction

The development artifact SHALL continue to contain the complete assembled source
plus generated provenance metadata.

The ordinary artifact SHALL continue to derive from the development artifact by
removing project-governed Doxygen documentation lines.  Its generated artifact
label SHALL identify it as the ordinary representation.

The minified artifact SHALL be constructed in two explicit parts:

1. the build-owned generated provenance header; and
2. the ordinary artifact body transformed by the pinned v0.1.0 release.

The generated header SHALL terminate with the exact marker:

```text
# End generated header.
```

The ordinary artifact body is the content after that marker.  That body SHALL be
piped through:

```text
awk -f vendor/awk-minifier.awk
```

using the configured `AWK_BIN` command.

The resulting transformed body SHALL be placed after a newly generated minified
artifact header.  That header SHALL identify the artifact as minified and record
the current version, build date, build commit, and the fact that AWK Minifier
v0.1.0 performed the body transformation.

Keeping the generated header outside the transformer input is intentional.  The
v0.1.0 transformer correctly removes ordinary comments, while the generated
header is build provenance rather than product source to be minified.

The current candidate version MUST NOT be substituted for the pinned v0.1.0
transformer.  The build MUST NOT silently fall back to copying `.dev.awk`,
self-minification, or an unpinned executable when the dependency is unavailable or
fails.

### Verification

CI SHALL verify all of the following:

- a fresh `make build` without prepared dependencies fails and does not create
  `vendor/`;
- `make deps` followed by `make deps-check` prepares and verifies
  `vendor/awk-minifier.awk`;
- all three artifact headers identify the correct representation;
- the minified header identifies v0.1.0 as the transformer;
- the body of `awk-minifier.min.awk` exactly matches a fresh v0.1.0 transformation
  of the body of `awk-minifier.awk`;
- all three artifacts satisfy the same public behavior suite; and
- repeated fresh builds from the same inputs produce identical artifact and
  checksum bytes.

Release validation SHALL perform the same previous-release lineage check before
tagging and publication.

## Dependency and Threat Analysis

The v0.1.0 artifact is executable build-time code and therefore expands the
trusted computing base as described by ADR-015.  It receives the current ordinary
AWK source body on STDIN, executes with the permissions of the build process, and
can influence the bytes later published as the minified release artifact.

The dependency is constrained by the following mitigations:

- the release version and URL are explicit;
- the expected SHA-256 digest is committed in `dependencies.txt`;
- Bashdeps verifies the exact bytes before prepared state is accepted;
- production builds do not grant the transformer network authority through the
  build recipe;
- the current candidate cannot silently replace the previous-release transformer;
- the resulting artifact receives the same behavior and portability tests as the
  other shipped representations; and
- release checksums and attestations cover the final published bytes.

Residual risk remains: a digest proves expected identity, not behavioral
correctness, and passing fixtures cannot prove equivalence for every valid AWK
program.  The project accepts that residual risk because the transformer is the
project's own previously reviewed release, transformation remains conservative,
and release verification exercises both lineage and observable behavior.

## Promises

1. v0.1.0 is the explicit production minifier until governance changes the pin.
2. The current candidate never minifies itself for production release
   provenance.
3. `make build` remains network-free and consumes only prepared dependency state.
4. Missing or failing minifier state fails the build rather than changing the
   production lineage.
5. Every shipped artifact retains inspectable generated provenance metadata.
6. The minified artifact body is exact output from the pinned previous release.
7. Dependency identity is authorized by the committed Bashdeps digest rather than
   by release checksum sidecars alone.

## Non-Promises

1. v0.1.0 is not claimed to produce the smallest possible AWK representation.
2. Pinning v0.1.0 does not prove that the transformer is free of semantic bugs.
3. The minified artifact is not promised to be byte-idempotent under every future
   AWK Minifier release because its build-owned provenance header is intentionally
   outside the transformed body.
4. `make build` on an unprepared checkout does not acquire missing dependencies.
5. The v0.1.0 pin is not permanent; a later accepted decision may advance the
   production transformer after appropriate review.

## Considered Alternatives

### Continue Copying Development to Minified

Rejected because the bootstrap condition has been satisfied.  Continuing the copy
would preserve a filename without exercising the product's intended production
role.

### Use the Current Candidate to Minify Itself

Rejected by ADR-019.  Candidate self-minification would collapse the independent
previous-release trust boundary that the bootstrap strategy was created to
establish.

### Transform the Complete Ordinary Artifact

Rejected because v0.1.0 removes ordinary comments, including the generated
provenance header.  The body is the correct transformation surface; the header is
build metadata and remains under Makefile control.

### Commit the v0.1.0 Artifact Directly to the Repository

Rejected because ADR-020 establishes Bashdeps as the repository-managed executable
dependency lifecycle.  A committed vendor copy would create a second acquisition
and update model.

### Download v0.1.0 During make build

Rejected because build must remain offline and dependency acquisition must stay
explicit.  `make deps` owns network convergence.

### Use the v0.1.0 Minified Artifact as the Transformer

Rejected because the ordinary v0.1.0 artifact is more inspectable while providing
the same public transformer behavior.  The dependency is a build trust anchor, so
the readable release representation is preferred.

## Consequences

Fresh checkouts must prepare repository dependencies before `make build`.  The
higher-level `make all` target continues to provide the convenience lifecycle that
runs dependency convergence and then builds.

The `.min.awk` artifact now becomes genuinely transformed rather than occupying a
bootstrap placeholder slot.  Its body has explicit previous-release lineage while
its generated header continues to provide inspectable current-build provenance.

CI and release workflows must no longer assert that `.dev.awk` and `.min.awk` are
identical.  They instead verify the pinned-transformer lineage directly.

Advancing the production minifier beyond v0.1.0 is a consequential dependency and
release-provenance change.  A future change should evaluate the new release,
update the manifest digest, update the governed minifier version, and record the
decision rather than silently following `latest`.

## Superseded Decisions

This ADR completes ADR-019's bootstrap transition and governs steady-state
production minification beginning after v0.1.0.  ADR-019 remains the historical
record explaining why v0.1.0 itself shipped with `.min.awk` equal to `.dev.awk`.

This ADR refines ADR-020 by selecting the previously anticipated AWK Minifier
dependency and making it required prepared state for production builds.

This ADR preserves ADR-006's three-artifact, metadata, checksum, and
behavior-equivalence principles while replacing the inherited Bash-Minifier
mechanism with the governed AWK Minifier pipeline.

## Related Decisions

- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-011: Conventional-Commit Semantic Releases and Late Tagging
- ADR-012: Standardize SHA-256 Checksum Companion Filenames
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
- ADR-019: Release Artifacts and Bootstrap Minification
- ADR-020: Bashdeps-Managed Tools and Standards
- ADR-021: AWK Documentation and Portability Testing
