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
specifies Bootstrap-style bashdeps preparation for executable repository tools.
ADR-025 keeps shared coding standards outside Make entirely by committing them as
ordinary repository content, while ADR-026 adds persistent release provenance
without adding synchronization machinery.

See [ADR-003](adr/ADR-003-make-as-canonical-orchestration-interface.md),
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md),
[ADR-025](adr/ADR-025-committed-coding-standards.md), and
[ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).

### ADR-004: Modular Source Assembly and Automatically Discovered Plugins

ADR-018 preserves explicit deterministic source ordering while superseding the
starter's automatically discovered runtime-plugin model.  AWK Minifier uses
responsibility-focused AWK modules and an explicit assembly order.

See [ADR-004](adr/ADR-004-modular-source-and-plugin-discovery.md),
[ADR-014](adr/ADR-014-modularity-as-maintenance-and-assembly-architecture.md), and
[ADR-018](adr/ADR-018-portable-awk-runtime-and-explicit-source-assembly.md).

### ADR-005: Dependency Management and Explicit Network Boundaries

bashdeps manages pinned executable repository dependencies while system packages
remain outside bashdeps scope.  Shared coding standards are not dependency-manager
inputs; ADR-025 commits them beneath `doc/standards/` so normal development and
coding-agent startup remain network-free, and ADR-026 records the selected release
in `.codingstandardrc`.

See [ADR-005](adr/ADR-005-dependency-management-and-network-boundaries.md),
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md),
[ADR-025](adr/ADR-025-committed-coding-standards.md), and
[ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).

### ADR-006: Three Release Artifact Flavors, Metadata, and Checksums

ADR-019 supersedes the Bash-specific artifact names and Bash-Minifier pipeline.
ADR-022 completed the bootstrap transition with a pinned previous-release AWK
Minifier, and ADR-024 advances that production transformer to v0.2.1 while
preserving build-owned provenance metadata outside the transformed body.

See [ADR-006](adr/ADR-006-release-artifact-flavors-and-metadata.md),
[ADR-019](adr/ADR-019-release-artifacts-and-bootstrap-minification.md),
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md), and
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md).

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

Every executable dependency expands the trusted computing base and is reviewed
according to execution context, authority, parsed inputs, side effects, transitive
surface, supply-chain posture, and failure behavior.  ADR-024 applies that review
to the v0.2.1 AWK Minifier used as executable production build input.  ADR-025 and
ADR-026 avoid adding a standards-updater dependency or CI authority boundary by
keeping shared standards as committed text with non-executable provenance.

See [ADR-015](adr/ADR-015-dependencies-as-explicit-attack-surface.md),
[ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md),
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md),
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md),
[ADR-025](adr/ADR-025-committed-coding-standards.md), and
[ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).

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
truthful bootstrap rule in which `.min.awk` equaled `.dev.awk`; ADR-022 established
the first previous-release production transformer, and ADR-024 advances the current
trust anchor to v0.2.1.

See [ADR-019](adr/ADR-019-release-artifacts-and-bootstrap-minification.md),
[ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md), and
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md).

### ADR-020: Bashdeps-Managed Tools and Standards

Make directly bootstraps only bashdeps, which manages pinned executable tools
through `dependencies.txt`.  ADR-025 supersedes ADR-020's former
`dependencies-standards.txt`, `make standards`, and `make standards-check`
requirements while leaving executable tool management intact.  ADR-026 adds
standards provenance without returning standards to the dependency lifecycle.

See [ADR-020](adr/ADR-020-bashdeps-managed-tools-and-standards.md),
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md),
[ADR-025](adr/ADR-025-committed-coding-standards.md), and
[ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).

### ADR-021: AWK Documentation and Portability Testing

Maintained product source follows the shared AWK documentation standard and uses
awk-doxygen for generated reference material.  The primary shell test harness is
parameterized by `AWK_BIN`, exercises modular source plus every shipped artifact,
and combines golden, semantic, negative, portability, idempotence, and regression
evidence.

See [ADR-021](adr/ADR-021-awk-documentation-and-portability-testing.md).

### ADR-022: Pin v0.1.0 as the Production Minification Transformer

AWK Minifier v0.1.0 was the first Bashdeps-pinned previous-release production
transformer after bootstrap.  It established the offline build boundary,
header/body separation, fail-closed dependency behavior, and exact lineage checks
that remain governing.  ADR-024 supersedes only its selected transformer version
and digest.

See [ADR-022](adr/ADR-022-pin-v0.1.0-production-minifier.md) and
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md).

### ADR-023: Grammar-Aware Newline Elimination

Successful transformed source contains no physical newlines except the one that
must terminate a preserved first-line shebang.  Grammar-optional newlines are
discarded, significant statement and rule terminators become semicolons, and
backslash-newline continuation disappears as a lexical continuation.  Structural
context distinguishes control headers, function definitions, and `do ... while`
trailers.  ADR-024 advances production provenance to the released v0.2.1
implementation of this behavior.

See [ADR-023](adr/ADR-023-grammar-aware-newline-elimination.md) and
[ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md).

### ADR-024: Pin v0.2.1 as the Production Minification Transformer

AWK Minifier v0.2.1 is the current production transformer for `.min.awk` artifact
bodies.  The immutable ordinary release artifact is pinned through Bashdeps by URL
and SHA-256 digest, retains the previous-release trust boundary from ADR-022, and
brings ADR-023 grammar-aware newline elimination into production minified bodies.
The v0.2.0 release is deliberately not selected because its tag points to the
earlier pre-ADR-023 implementation.

See [ADR-024](adr/ADR-024-pin-v0.2.1-production-minifier.md).

### ADR-025: Commit Shared Coding Standards as Repository Content

The complete `wesley-dean/coding_standards` `standards/` tree is committed beneath
`doc/standards/` and preserved as ordinary reviewable repository content.  AWK
Minifier contains no dedicated standards downloader, synchronization Make target,
or update workflow.  ADR-026 preserves that committed-snapshot model while
superseding ADR-025's earlier choice to omit persistent provenance.

See [ADR-025](adr/ADR-025-committed-coding-standards.md) and
[ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).

### ADR-026: Versioned Coding Standards Provenance

`.codingstandardrc` records the canonical standards source, concrete released
version, release-archive SHA-256 digest, and managed `doc/standards` destination.
Standards refreshes replace the complete managed tree and are proposed through a
normal pull request while steady-state development remains network-free.
Applicable shared standards are governance rather than suggestions; accepted
repository ADRs or explicit project policy may visibly refine or supersede them.

See [ADR-026](adr/ADR-026-versioned-coding-standards-provenance.md).
