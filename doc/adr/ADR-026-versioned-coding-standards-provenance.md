# ADR-026: Versioned Coding Standards Provenance

Date: 2026-09-14

## Status

Accepted

## Supersedes

ADR-026 supersedes ADR-025 where ADR-025 rejects persistent standards provenance.
ADR-025 remains historical context for the decision to commit the complete
standards snapshot and to avoid consumer-side fetching machinery.

## Context

AWK Minifier commits the complete shared coding-standards library beneath
`doc/standards/` so humans and coding agents receive governance in an ordinary
checkout.  The canonical `wesley-dean/coding_standards` repository now publishes
versioned releases containing `coding_standards.tar.gz` and
`coding_standards.tar.gz.sha256`.

The committed snapshot alone records the bytes AWK Minifier contains, but it does
not directly record which upstream release and verified release artifact those
bytes represent.  A small provenance file can provide that identity without
reintroducing a downloader, Make target, dependency manifest, or update workflow.

## Decision

The project root SHALL contain `.codingstandardrc` as non-executable repository
configuration data with these fields:

```toml
source = "https://github.com/wesley-dean/coding_standards.git"
version = "coding_standards@v1.0.3"
sha256 = "<verified-release-archive-sha256>"
destination = "doc/standards"
```

`version` SHALL always identify a concrete released version.  A request for
`latest` is resolved once to the current latest stable release and the concrete
version is recorded; `latest` itself is never persisted.

`sha256` records the digest of the selected release's
`coding_standards.tar.gz` artifact.  `destination` identifies the managed
repository-relative standards tree.

`doc/standards/` SHALL represent the complete selected release.  A standards
adoption, upgrade, downgrade, refresh, or same-version repair replaces the managed
tree rather than overlaying new content on the old tree.  Imported standards are
not edited locally.

AWK Minifier SHALL NOT contain permanent standards-fetching machinery.  Standards
updates are performed by an authorized maintainer or coding agent outside the
steady-state project lifecycle and proposed through a pull request against the
default branch.

Applicable standards under `doc/standards/` are governing project requirements,
not suggestions.  General and cross-cutting standards apply where relevant; AWK
standards apply to maintained AWK source; other language standards apply only when
their subject matter is relevant.  Content under `examples/` is illustrative and
non-normative unless a governing standard says otherwise.

An accepted AWK Minifier ADR or explicit repository policy may refine or
supersede a shared standard for this repository.  Such exceptions must be visible
governance decisions rather than silent deviations or edits to imported files.

## Consequences

The repository carries one small provenance file in addition to the committed
standards snapshot.  Normal builds, tests, documentation generation, and coding
agent startup remain network-free.  Standards refreshes remain ordinary reviewed
repository changes, while audits can determine the exact upstream release and
archive digest without reconstructing that information from pull-request history.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-020: Bashdeps-Managed Tools and Standards
- ADR-025: Commit Shared Coding Standards as Repository Content
