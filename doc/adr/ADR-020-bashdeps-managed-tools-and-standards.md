# ADR-020: Bashdeps-Managed Tools and Standards

Date: 2026-09-12

## Status

Accepted, partially superseded by ADR-025.

ADR-025 supersedes this ADR only for shared coding-standards acquisition,
verification, materialization, and lifecycle commands.  This ADR remains governing
for bashdeps-managed executable repository tools and their explicit network and
offline-verification boundaries.

## Context

The project needs reproducible repository tooling such as `awk-doxygen`, `adrctl`,
and eventually a previously released AWK Minifier.  It also consumes shared coding
and documentation standards maintained in `wesley-dean/coding_standards`.

Bootstrap already demonstrates the desired dependency lifecycle: Make directly
bootstraps only bashdeps, validates its committed digest before execution, and
uses bashdeps manifests for every other repository-managed dependency.  Network
convergence and offline verification are deliberately separate operations.

Standards differ from executable tooling in destination and update cadence.  They
are normative imported documentation and should remain visibly synchronized from
the upstream standards repository rather than copied and edited locally.

## Decision Drivers

- Reuse the proven Bootstrap dependency lifecycle.
- Keep network access explicit and auditable.
- Pin executable tools and normative standards to immutable bytes.
- Avoid hidden standards refreshes during ordinary builds.
- Preserve upstream directory structure so imported paths remain predictable.
- Keep build, documentation, and verification usable offline after preparation.

## Decision

The Makefile SHALL follow the Bootstrap dependency pattern.

Make directly owns only the bootstrap of `vendor/bashdeps.bash`.  The bootstrap
recipe SHALL validate the committed SHA-256 digest, reuse a valid cached copy,
download to a temporary file when repair is necessary, validate the candidate,
and move it atomically into place.  `verify-bashdeps` SHALL be offline and
non-repairing.

### Tool dependencies

Repository-managed executable tools SHALL be declared in `dependencies.txt`.
`make deps` MAY access the network and SHALL use bashdeps `sync` to converge those
dependencies.  `make deps-check` SHALL use bashdeps `verify`, SHALL NOT repair
state, and SHALL not intentionally access the network.

Expected tool dependencies include:

- `awk-doxygen` for AWK source reference filtering;
- `adrctl` for generated ADR navigation; and
- after bootstrap, a previously released AWK Minifier for production minification.

A tool SHALL NOT remain in the manifest merely because template-bash previously
used it.  In particular, Bash-Minifier and bash-doxygen are removed unless a
current maintained source path actually requires them.

### Standards dependencies

The standards-management decision in this section is historical and is
superseded by ADR-025.

This ADR originally required shared standards to be declared separately in
`dependencies-standards.txt`, synchronized by bashdeps through `make standards`,
verified by `make standards-check`, and materialized beneath `doc/standards/`.
ADR-025 replaces that mechanism with a tracked `.codingstandardrc`, a manually
dispatched GitHub Actions updater, one released standards archive, and a committed
`doc/standards/` snapshot.

Imported standards remain externally managed copies.  They SHALL NOT be edited
locally; changes belong in `coding_standards`, followed by an intentional released
update in this repository.

Ordinary `build`, `test`, and `docs` targets SHALL NOT invoke standards acquisition
or silently refresh normative documentation.

## Promises

1. bashdeps is the only executable repository dependency manager Make bootstraps
   directly.
2. Tool convergence is explicit through `make deps`.
3. `deps-check` is offline and non-repairing.
4. Imported standards are not forked through local edits.
5. Build and documentation targets consume prepared state rather than hiding
   network acquisition.
6. Shared-standards acquisition is governed by ADR-025 rather than by this ADR's
   historical second-manifest design.

## Non-Promises

1. The repository does not install operating-system packages.
2. Pinning and digests do not establish that dependency behavior is safe.
3. Running `make build` on an unprepared checkout does not promise to acquire
   missing executable tools.
4. This ADR no longer defines the active standards-update mechanism.

## Considered Alternatives

### Have Make Download Every Tool Directly

Rejected because it duplicates acquisition, checksum, destination, and verification
logic already centralized in bashdeps.

### Put Standards in dependencies.txt

Rejected because standards use a different destination and lifecycle from
executable tools.  ADR-025 later supersedes the original separate-manifest answer
with a GitHub Actions release-archive workflow.

### Vendor Hand-Maintained Copies of Standards

Rejected because local edits would create ambiguous authority and drift from the
standards repository.  ADR-025 preserves this concern by treating committed
`doc/standards/` files as externally managed snapshots rather than locally forked
standards.

### Track Mutable main URLs Without Digests

Rejected because reproducibility requires immutable source identity plus expected
bytes.

### Make build Run deps or standards

Rejected because build should remain an offline consumer of prepared state.  The
higher-level `all` target can explicitly compose executable dependency preparation
without changing the meaning of `build` itself.  ADR-025 removes standards
synchronization from Make entirely.

## Consequences

The Makefile retains the Bootstrap-style bashdeps bootstrap for executable tools.
The original second-manifest standards lifecycle is no longer active; ADR-025 owns
that concern.

## Superseded Decisions

This ADR refines ADR-003 by specifying the Make target and network semantics used
by this product.

This ADR refines ADR-005 and ADR-015.  Their dependency-boundary and attack-surface
principles remain governing; this ADR replaces template-specific dependency
choices with AWK Minifier's actual executable tools.

ADR-025 supersedes this ADR's standards-specific requirements.

## Related Decisions

- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-017: Generate ADR Navigation Ephemerally
- ADR-019: Release Artifacts and Bootstrap Minification
- ADR-025: Manage Shared Coding Standards Through GitHub Releases
