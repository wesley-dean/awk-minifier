# ADR-024: Pin v0.2.1 as the Production Minification Transformer

Date: 2026-09-12

## Status

Accepted

## Context

ADR-019 established a bootstrap rule for AWK Minifier releases: the first
trustworthy release could not depend on an earlier AWK Minifier, so its
`awk-minifier.min.awk` artifact truthfully occupied the minified release slot
without self-hosting the current candidate.  ADR-022 completed that bootstrap
transition by selecting the ordinary artifact from v0.1.0 as the first independent
previous-release transformer.

That decision deliberately made the production transformer a versioned trust
anchor rather than a moving reference.  The current candidate is not permitted to
create its own production `.min.awk` body.  A newer transformer becomes eligible
only after it has itself been released, reviewed as an independent artifact, and
explicitly selected by governance.

ADR-023 subsequently introduced grammar-aware physical-newline elimination.  The
new transformer distinguishes grammar-optional newlines from statement and rule
terminators, removes portable explicit continuations between tokens, preserves the
single newline required after a shebang, and rejects literal-internal
backslash-newline where supported AWK implementations disagree.  That behavior was
merged with the previous-release build pipeline and released as AWK Minifier
v0.2.1.

The immutable v0.2.1 GitHub release points to merged commit
`eaca041f3c6832108c5dd426cb18725b13b1fe84`.  Its ordinary
`awk-minifier.awk` artifact is independently published and has SHA-256 digest:

```text
567cff8aaf95010efc6bbcf1d84c0dbd3de58566bd10fa7df54ef6178b3fc464
```

Version v0.2.0 is not selected for this role.  Although that immutable release
exists, its tag points to the earlier pre-ADR-023 commit
`7f2f1377858e5f3f4cd324c6acb24bf76aeaee8b`.  Its version label therefore does
not identify the merged grammar-aware implementation that this decision intends
to trust.  Selecting v0.2.0 merely because its semantic version appears to precede
v0.2.1 would provide misleading provenance and would not advance the production
minification behavior.

The v0.2.1 release creates the first opportunity to advance the production trust
anchor to a released implementation that itself satisfies ADR-023.  Doing so
means subsequent `.min.awk` bodies can use grammar-aware newline elimination in
production without allowing the current candidate to self-host.

## Decision Drivers

- Preserve the previous-release trust boundary established by ADR-019 and ADR-022.
- Advance production minification only to a release containing the reviewed
  grammar-aware newline implementation.
- Select artifacts by verified release provenance and bytes rather than by version
  label alone.
- Keep executable build dependencies pinned to immutable URLs and committed
  SHA-256 digests.
- Preserve explicit dependency acquisition and network-free builds.
- Preserve generated provenance metadata outside the transformed body.
- Keep exact previous-release lineage verifiable in CI and release automation.
- Fail closed when the pinned transformer is absent, corrupted, or fails.

## Decision

AWK Minifier v0.2.1 SHALL be the production transformer for subsequent
`.min.awk` builds until another accepted decision changes that pin.

The ordinary v0.2.1 release artifact SHALL be declared in `dependencies.txt` as:

```text
id=wesley-dean/awk-minifier@0.2.1
url=https://github.com/wesley-dean/awk-minifier/releases/download/v0.2.1/awk-minifier.awk
dest=vendor/awk-minifier.awk
digest=sha256:567cff8aaf95010efc6bbcf1d84c0dbd3de58566bd10fa7df54ef6178b3fc464
```

The actual Bashdeps manifest SHALL retain that declaration on one physical line.

`make deps` MAY acquire or repair the pinned v0.2.1 dependency.  `make deps-check`
SHALL verify the prepared bytes without network repair.  `make build` SHALL remain
network-free and SHALL fail with an actionable diagnostic when
`vendor/awk-minifier.awk` is missing or unusable.

### Production artifact construction

The three-artifact model remains unchanged:

1. `awk-minifier.dev.awk` contains assembled maintained source and documentation;
2. `awk-minifier.awk` removes only project-governed Doxygen documentation lines;
   and
3. `awk-minifier.min.awk` contains a build-owned provenance header followed by the
   ordinary artifact body transformed by the pinned previous release.

The exact marker:

```text
# End generated header.
```

continues to delimit build-owned provenance from product source.  Only the body
after that marker is supplied to:

```text
awk -f vendor/awk-minifier.awk
```

using the configured `AWK_BIN` command.

The final minified header SHALL identify AWK Minifier v0.2.1 as the transformer.
The current candidate MUST NOT replace the pinned v0.2.1 executable during
production construction.  Missing or failing prepared state MUST NOT cause a
fallback to the candidate, an unpinned executable, or a copy of another artifact.

### Representation consequence

Unlike v0.1.0, v0.2.1 implements ADR-023's grammar-aware newline elimination.
The ordinary artifact body supplied to the transformer has no shebang because the
build-owned header, including the artifact shebang, has already been removed from
the transformation surface.  Therefore the transformed production body is
expected to contain zero physical newline bytes.

The complete `.min.awk` artifact remains intentionally multiline at the beginning
because its build-owned provenance header is outside the transformed body.  The
zero-newline invariant applies to the transformed AWK source body, not to the
separate metadata envelope.

### Verification

CI and release validation SHALL verify all of the following:

- dependency preparation resolves the committed v0.2.1 URL and SHA-256 digest;
- an unprepared `make build` fails without silently acquiring dependencies;
- the generated minified header identifies v0.2.1;
- the body of `awk-minifier.min.awk` exactly matches a fresh transformation of the
  current ordinary artifact body using `vendor/awk-minifier.awk`;
- the production minified body satisfies ADR-023's expected physical-line shape;
- all shipped artifact forms satisfy the same public behavior suite; and
- repeated builds from identical inputs remain byte-for-byte deterministic.

The dependency digest is the authorization boundary for prepared build-time code.
Release checksum companions remain distribution-integrity evidence and do not
replace the committed Bashdeps digest.

## Dependency and Threat Analysis

The v0.2.1 ordinary artifact is executable build-time code.  As with v0.1.0, it is
part of the trusted computing base and runs with the permissions of the build
process.  It consumes the current ordinary AWK body from STDIN and can influence
the bytes later published as the minified release artifact.

The following controls remain in force:

- the selected release version and URL are explicit;
- the expected SHA-256 digest is committed in `dependencies.txt`;
- Bashdeps verifies prepared bytes before the dependency is accepted;
- production build recipes do not acquire the transformer from the network;
- the current candidate cannot silently replace the previous release;
- exact transformed-body lineage is compared in CI and release validation;
- every shipped representation receives public behavior testing; and
- final release bytes receive checksums and attestations.

The v0.2.1 advancement does not remove residual semantic risk.  A digest proves
identity, not correctness, and the test corpus cannot prove equivalence for every
possible portable AWK program.  The project accepts that residual risk because the
selected transformer is its own previously reviewed and released implementation,
its more aggressive newline behavior is governed by ADR-023, and multiple AWK
implementations exercise the behavior contract.

## Promises

1. v0.2.1 is the explicit production minifier until governance changes the pin.
2. The production trust anchor is selected by release provenance and committed
   bytes, not by an unqualified `latest` reference.
3. The current candidate does not minify itself for production release provenance.
4. `make build` remains network-free and consumes only prepared dependency state.
5. Missing or failing minifier state fails the build rather than changing lineage.
6. Every shipped artifact retains inspectable build provenance metadata.
7. The minified artifact body is exact output from the pinned previous release.
8. Production minified bodies use ADR-023 grammar-aware newline elimination.

## Non-Promises

1. v0.2.1 is not claimed to produce the mathematically smallest valid AWK source.
2. Pinning v0.2.1 does not prove that the transformer is free of semantic bugs.
3. The complete `.min.awk` file is not a zero-newline file because build-owned
   provenance intentionally precedes the transformed body.
4. `make build` on an unprepared checkout does not acquire missing dependencies.
5. v0.2.1 is not permanent; a future accepted decision may advance the production
   transformer after an appropriate independent release and review.

## Considered Alternatives

### Continue Using v0.1.0

Rejected because v0.2.1 is now an independently released transformer containing
the reviewed ADR-023 behavior.  Keeping v0.1.0 would preserve the previous-release
boundary but unnecessarily prevent production `.min.awk` bodies from receiving the
newline minimization already accepted as product behavior.

### Pin v0.2.0

Rejected because the v0.2.0 tag points to the earlier pre-ADR-023 commit.  Its
release label does not correspond to the merged grammar-aware implementation that
motivates this trust-anchor advancement.

### Follow the Latest Release Automatically

Rejected because release provenance is a security and reproducibility boundary.
An automatically moving version or URL would bypass explicit review, governance,
and the committed digest authorization model.

### Use the Current Candidate

Rejected for the same reason as ADR-019 and ADR-022: self-hosting the current
candidate removes the independent previous-release trust boundary.

### Use the v0.2.1 Minified Artifact as the Transformer

Rejected because the ordinary artifact remains the more inspectable representation
of the same public transformer behavior.  Build-time trusted code should favor the
readable release form when behavior is equivalent.

### Rewrite ADR-022 in Place

Rejected because ADR-022 is the historical decision that established the first
steady-state production trust anchor.  Preserving it makes the progression from
bootstrap to v0.1.0 and then to v0.2.1 auditable.

## Consequences

Future builds synchronize a larger v0.2.1 ordinary transformer in place of the
v0.1.0 dependency.  Production `.min.awk` bodies become substantially more compact
because the pinned transformer now performs grammar-aware newline elimination.

The build, testing, release, and threat boundaries established by ADR-022 remain
unchanged.  Only the selected previous-release implementation and the resulting
body representation advance.

CI, release verification, generated artifact metadata, contributor guidance, and
repository-facing documentation must identify v0.2.1 as the production minifier.
Exact lineage continues to be checked by transforming the current ordinary body
with the prepared dependency and comparing those bytes with the generated minified
body.

A later trust-anchor advancement remains an explicit governance event.  It should
verify the target release/tag relationship, immutable asset digest, behavioral
changes, portability evidence, and security implications before changing the pin.

## Superseded Decisions

This ADR supersedes ADR-022 only with respect to the selected production minifier
version and its artifact digest.  ADR-022 remains the historical record of the
bootstrap-to-steady-state transition and continues to govern the underlying
previous-release trust model, header/body separation, network boundary, fail-closed
behavior, and exact-lineage verification where those provisions are not refined by
this ADR.

ADR-023 continues to govern grammar-aware newline behavior.  This ADR changes the
production release pipeline so that the independently released implementation of
ADR-023 is now the transformer used for subsequent `.min.awk` bodies.

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
- ADR-022: Pin v0.1.0 as the Production Minification Transformer
- ADR-023: Grammar-Aware Newline Elimination
