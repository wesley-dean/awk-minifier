# Architectural Decisions

This document is a concise map of AWK Minifier's Architecture Decision Records.
It is a discovery aid, not a substitute for the ADR corpus.  When a summary and a
governing ADR appear to conflict, read the ADR and surface the conflict rather
than silently choosing the shorter wording.

The reusable engineering posture behind these decisions is summarized separately
in [`doc/engineering-philosophy.md`](engineering-philosophy.md).  ADRs remain the
binding architectural record when a concrete decision exists.

## Accepted Decisions

### ADR-000: Capability Scope, Epistemic Honesty, and Separation of Concerns

Accuracy, explicit capability limits, evidence-oriented reasoning, separation of
concerns, and resistance to performative agreement are foundational project
constraints.

See [ADR-000](adr/ADR-000-capability-scope-and-epistemic-honesty.md).

### ADR-001: Documentation and Decision Hierarchy

ADRs preserve durable reasoning; `doc/decisions.md` summarizes current decisions;
`AGENTS.md` remains a concise operational map; specifications describe normative
public behavior when needed; Doxygen comments own implementation contracts; and
tests provide evidence without superseding architectural intent.

See [ADR-001](adr/ADR-001-documentation-and-decision-hierarchy.md).

### ADR-002: Bash Runtime and Portability Baseline

The inherited Bash 4.3 runtime baseline is superseded for product code by ADR-018.
Bash may still be used for repository orchestration where appropriate, but the
transformer itself is portable AWK.

See [ADR-002](adr/ADR-002-bash-runtime-and-portability-baseline.md) and
[ADR-018](adr/ADR-018-portable-awk-runtime-and-explicit-source-assembly.md).

### ADR-003: Make as the Canonical Orchestration Interface

GNU Make remains the canonical local and CI orchestration surface.  ADR-020
specifies Bootstrap-style bashdeps preparation plus separate tool and standards
lifecycles for this repository.

See [ADR-003](adr/ADR-003-make-as-canonical-orchestration-interface.md) and
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md).

### ADR-004: Modular Source Assembly and Automatically Discovered Plugins

ADR-018 preserves explicit deterministic source ordering while superseding the
starter's automatically discovered runtime-plugin model.  AWK Minifier uses
responsibility-focused AWK modules and an explicit assembly order.

See [ADR-004](adr/ADR-004-modular-source-and-plugin-discovery.md),
[ADR-014](adr/ADR-014-modularity-as-maintenance-and-assembly-architecture.md), and
[ADR-018](adr/ADR-018-portable-awk-runtime-and-explicit-source-assembly.md).

### ADR-005: Dependency Management and Explicit Network Boundaries

bashdeps manages pinned repository dependencies while system packages remain
outside bashdeps scope.  ADR-020 preserves explicit network convergence and
offline verification while adding a separate standards manifest/destination.

See [ADR-005](adr/ADR-005-dependency-management-and-network-boundaries.md) and
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md).

### ADR-006: Three Release Artifact Flavors, Metadata, and Checksums

ADR-019 supersedes the Bash-specific artifact names and Bash-Minifier pipeline.
ADR-022 completes the bootstrap transition by using the pinned v0.1.0 AWK
Minifier for the `.min.awk` body while preserving build-owned provenance metadata.

See [ADR-006](adr/ADR-006-release-artifact-flavors-and-metadata.md),
[ADR-019](adr/ADR-019-release-artifacts-and-bootstrap-minification.md), and
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md).

### ADR-007: Doxygen-Based Verbose Source Documentation Standard

ADR-021 supersedes the Bash-specific source convention.  Maintained product source
uses the shared AWK documentation standard and the pinned awk-doxygen filter.

See [ADR-007](adr/ADR-007-doxygen-verbose-source-documentation.md) and
[ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md).

### ADR-008: Documentation-Driven, Test-Second Development

Consequential behavior should be documented architecturally and at the interface
level before tests encode the intended contract and implementation follows.
Exploration may precede documentation, but exploratory behavior should not become
architecture silently.

See [ADR-008](adr/ADR-008-documentation-driven-test-second-development.md).

### ADR-009: Observable Behavior Testing Across Shipped Artifacts

ADR-021 supersedes Bats as the required primary product harness while preserving
the invariant that every shipped artifact receives the same public behavior suite.
ADR-023 adds physical-line count, grammar-aware newline classification, and
candidate self-minification to the evidence required for newline behavior.

See [ADR-009](adr/ADR-009-observable-behavior-testing.md),
[ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md), and
[ADR-023](adr/ADR-023-grammar-aware-newline-elimination.md).

### ADR-010: Generated Reference Documentation Is Ephemeral

Doxygen reference output remains generated, ignored state.  ADR-021 changes the
product source filter from bash-doxygen to awk-doxygen while preserving the
ephemeral documentation model.

See [ADR-010](adr/ADR-010-generated-reference-documentation.md) and
[ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md).

### ADR-011: Conventional-Commit Semantic Releases and Late Tagging

Release versions derive from Conventional Commits, and tags/releases are created
only after the exact intended artifacts have passed checks, tests, checksum
verification, compatibility validation, and attestation.

See [ADR-011](adr/ADR-011-conventional-semver-and-late-tagging.md).

### ADR-012: Standardize SHA-256 Checksum Companion Filenames

Current builds and releases use `.sha256` companions and do not publish duplicate
`.256` files.  Historical `.256` release assets remain valid where they already
exist.

See [ADR-012](adr/ADR-012-standardize-sha256-checksum-companion-filenames.md).

### ADR-013: Repository-Facing Documentation and Template Hygiene

Repository-facing documentation is maintained product material, not disposable
boilerplate.  The AWK migration therefore includes removal of template-bash
residue from README, contribution guidance, workflows, and generated documentation
configuration.

See [ADR-013](adr/ADR-013-repository-facing-documentation-and-template-hygiene.md).

### ADR-014: Modularity as Maintenance and Assembly Architecture

Responsibility-focused maintained source, explicit dependency order,
deterministic assembly, and standalone consumer artifacts remain governing.
ADR-018 chooses those principles without carrying the starter's runtime registry
or plugin machinery forward.

See [ADR-014](adr/ADR-014-modularity-as-maintenance-and-assembly-architecture.md)
and [ADR-018](adr/ADR-018-portable-awk-runtime-and-explicit-source-assembly.md).

### ADR-015: Dependencies as Explicit Attack Surface

Every dependency expands the trusted computing base and is reviewed according to
execution context, authority, parsed inputs, side effects, transitive surface,
supply-chain posture, and failure behavior.  ADR-022 applies that review to the
v0.1.0 AWK Minifier now used as executable production build input.

See [ADR-015](adr/ADR-015-dependencies-as-explicit-attack-surface.md),
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md), and
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md).

### ADR-016: Explicit Threat Modeling for Security-Relevant Changes

Security-relevant changes should preserve an explicit threat model of assets,
trusted computing base, data and authority flows, mitigations, evidence, residual
risk, and review triggers.

See [ADR-016](adr/ADR-016-explicit-threat-modeling-for-security-relevant-changes.md)
and [`doc/threat-modeling.md`](threat-modeling.md).

### ADR-017: Generate ADR Navigation Ephemerally

The linked ADR landing page is generated from maintained framing and the current
ADR corpus with a pinned adrctl release.  ADR-021 preserves this model while
switching source-code documentation to awk-doxygen.

See [ADR-017](adr/ADR-017-generate-adr-navigation-ephemerally.md) and
[ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md).

### ADR-018: Portable AWK Runtime and Explicit Source Assembly

The product is implemented in portable AWK as explicitly ordered,
responsibility-focused modules that are directly runnable with repeated `awk -f`
arguments and deterministically assembled into standalone artifacts.  ADR-023
refines its conservative gap handling with explicit grammar context so physical
newlines can be removed without abandoning semantic-preservation priority.

See [ADR-018](adr/ADR-018-portable-awk-runtime-and-explicit-source-assembly.md) and
[ADR-023](adr/ADR-023-grammar-aware-newline-elimination.md).

### ADR-019: Release Artifacts and Bootstrap Minification

Every normal release publishes `awk-minifier.dev.awk`, `awk-minifier.awk`, and
`awk-minifier.min.awk` plus `.sha256` companions.  Version v0.1.0 completed the
truthful bootstrap rule in which `.min.awk` equaled `.dev.awk`; ADR-022 now governs
the previous-release production minification path for later releases.

See [ADR-019](adr/ADR-019-release-artifacts-and-bootstrap-minification.md) and
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md).

### ADR-020: Bashdeps-Managed Tools and Standards

Make directly bootstraps only bashdeps, which then manages pinned executable tools
through `dependencies.txt`.  The tool manifest now includes the v0.1.0 AWK
Minifier selected by ADR-022, while shared normative files from
`coding_standards` retain their separate `dependencies-standards.txt` lifecycle.

See [ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md) and
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md).

### ADR-021: AWK Documentation and Portability Testing

Maintained product source follows the shared AWK documentation standard and uses
awk-doxygen for generated reference material.  The primary shell test harness is
parameterized by `AWK_BIN`, exercises modular source plus every shipped artifact,
and combines golden, semantic, negative, portability, idempotence, and regression
evidence.

See [ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md).

### ADR-022: Pin v0.1.0 as the Production Minification Transformer

AWK Minifier v0.1.0 is pinned through Bashdeps as
`vendor/awk-minifier.awk` and is the production transformer for subsequent
`.min.awk` artifact bodies.  Builds remain offline after dependency preparation,
preserve generated provenance outside the transformed body, fail closed when the
pinned transformer is unavailable, and verify exact previous-release lineage in
CI and release validation.

See [ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md).

### ADR-023: Grammar-Aware Newline Elimination

Successful transformed source contains no physical newlines except the one that
must terminate a preserved first-line shebang.  Grammar-optional newlines are
discarded, significant statement and rule terminators become semicolons, and
backslash-newline continuation disappears as a lexical continuation.  Structural
context distinguishes control headers, function definitions, and `do ... while`
trailers, while production `.min.awk` provenance remains governed independently by
ADR-022.

See [ADR-023](adr/ADR-023-grammar-aware-newline-elimination.md).
