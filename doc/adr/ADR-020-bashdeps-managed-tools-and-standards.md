# ADR-020: Bashdeps-Managed Tools and Standards

Date: 2026-09-12

## Status

Accepted, partially superseded by ADR-025.

ADR-025 supersedes this ADR only for shared coding-standards acquisition and
lifecycle.  This ADR remains governing for bashdeps-managed executable repository
tools and their explicit network and offline-verification boundaries.

## Context

The project needs reproducible repository tooling such as `awk-doxygen`, `adrctl`,
and a previously released AWK Minifier.  It also consumes shared coding and
documentation standards maintained in `wesley-dean/coding_standards`.

Bootstrap demonstrates the desired executable dependency lifecycle: Make directly
bootstraps only bashdeps, validates its committed digest before execution, and
uses bashdeps manifests for every other repository-managed executable dependency.
Network convergence and offline verification are deliberately separate operations.

ADR-020 originally extended that dependency model to shared standards through a
second manifest and dedicated Make targets.  ADR-025 later supersedes that portion
of this decision.  Shared standards are now ordinary committed repository content
beneath `doc/standards/` and do not participate in the dependency manager.

## Decision Drivers

- Reuse the proven Bootstrap dependency lifecycle for executable repository tools.
- Keep network access explicit and auditable.
- Pin executable tools to immutable bytes.
- Keep build, documentation, and verification usable offline after tool
  preparation.
- Keep shared governance material available in ordinary repository checkouts.
- Avoid treating non-executable shared documentation as an executable dependency.

## Decision

The Makefile SHALL follow the Bootstrap dependency pattern for executable
repository tools.

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
- a previously released AWK Minifier for production minification.

A tool SHALL NOT remain in the manifest merely because template-bash previously
used it.  In particular, Bash-Minifier and bash-doxygen are removed unless a
current maintained source path actually requires them.

### Shared standards

The standards-management requirements originally contained in this ADR are
historical and superseded by ADR-025.

This ADR originally required `dependencies-standards.txt`, `make standards`, and
`make standards-check` to synchronize individually pinned files beneath
`doc/standards/`.  Those mechanisms are removed.

ADR-025 now requires the complete shared standards snapshot to be committed as
ordinary repository content beneath `doc/standards/`.  AWK Minifier contains no
dedicated standards-fetching mechanism.  Imported shared standards are not edited
locally; changes belong in `wesley-dean/coding_standards` and are adopted through
an intentional repository update.

Ordinary `build`, `test`, and `docs` targets SHALL NOT invoke standards acquisition
or silently refresh normative documentation.

## Promises

1. bashdeps is the only executable repository dependency manager Make bootstraps
   directly.
2. Tool convergence is explicit through `make deps`.
3. `deps-check` is offline and non-repairing.
4. Build and documentation targets consume prepared executable-tool state rather
   than hiding network acquisition.
5. Shared standards are governed by ADR-025 and do not participate in bashdeps.
6. Imported shared standards are not forked through local edits.

## Non-Promises

1. The repository does not install operating-system packages.
2. Pinning and digests do not establish that dependency behavior is safe.
3. Running `make build` on an unprepared checkout does not promise to acquire
   missing executable tools.
4. This ADR no longer defines a standards-update command, downloader, manifest,
   or verification mechanism.

## Considered Alternatives

### Have Make Download Every Tool Directly

Rejected because it duplicates acquisition, checksum, destination, and verification
logic already centralized in bashdeps.

### Put Standards in dependencies.txt

Rejected because standards are shared governance documents rather than executable
repository tools.  ADR-025 supersedes the earlier separate-manifest design with a
committed snapshot that is maintained through ordinary repository changes.

### Maintain Standards Through a Dedicated Consumer Updater

Rejected by ADR-025.  A consumer-side updater adds configuration, network logic,
credentials or CI authority, and archive or checksum handling to perform an
operation an authorized maintainer or coding agent can already propose directly as
a reviewed Git change.

### Maintain Independent Local Standards

Rejected because local edits would create ambiguous authority and drift from the
canonical `coding_standards` repository.  The committed `doc/standards/` files are
snapshots, not an independent fork.

### Make build Run deps or Standards Acquisition

Rejected because build should remain an offline consumer of prepared and committed
state.  The higher-level `all` target can explicitly compose executable dependency
preparation without changing the meaning of `build` itself.

## Consequences

The Makefile retains the Bootstrap-style bashdeps bootstrap and manifest lifecycle
for executable tools only.  Shared standards travel with the repository checkout
as committed documentation and require no Make target or dependency manifest.

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
- ADR-025: Commit Shared Coding Standards as Repository Content
