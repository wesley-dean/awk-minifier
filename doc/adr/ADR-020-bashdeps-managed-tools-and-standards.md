# ADR-020: Bashdeps-Managed Tools and Standards

Date: 2026-09-12

## Status

Accepted

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

Shared standards SHALL be declared separately in
`dependencies-standards.txt`.  They SHALL be pinned to immutable raw GitHub URLs
and committed SHA-256 digests from `wesley-dean/coding_standards`.

`make standards` MAY access the network and SHALL use bashdeps `sync` with:

```text
--dest-root doc/standards
```

`make standards-check` SHALL use bashdeps `verify` with the same destination root,
remain offline/non-repairing, and fail when tracked imported standards differ from
the pinned upstream bytes.

Upstream `standards/` files SHALL be mapped beneath `doc/standards/` while
preserving their relative hierarchy.  Upstream `examples/` files SHALL be mapped
beneath `doc/standards/examples/` while preserving their relative hierarchy.

Imported standards and examples are synchronized copies.  They SHALL NOT be
edited locally; changes belong in `coding_standards`, followed by an intentional
pin update and synchronization here.

Ordinary `build`, `test`, and `docs` targets SHALL NOT invoke `make standards` or
silently refresh normative documentation.  The `all` lifecycle MAY prepare tool
dependencies before build, matching Bootstrap, but standards remain an explicit
separate convergence action.

## Promises

1. bashdeps is the only dependency manager Make bootstraps directly.
2. Tool convergence is explicit through `make deps`.
3. Standards convergence is explicit through `make standards`.
4. `deps-check` and `standards-check` are offline and non-repairing.
5. Shared standards preserve upstream directory structure under
   `doc/standards/`.
6. Imported standards are not forked through local edits.
7. Build and documentation targets consume prepared state rather than hiding
   network acquisition.

## Non-Promises

1. The repository does not install operating-system packages.
2. Pinning and digests do not establish that dependency behavior is safe.
3. Empty upstream example directories are not promised locally because Git does
   not preserve empty directories.
4. Running `make build` on an unprepared checkout does not promise to acquire
   missing tools.

## Considered Alternatives

### Have Make Download Every Tool Directly

Rejected because it duplicates acquisition, checksum, destination, and verification
logic already centralized in bashdeps.

### Put Standards in dependencies.txt

Rejected because standards use a different destination root and should not be
silently refreshed as part of ordinary tool preparation.

### Vendor Hand-Maintained Copies of Standards

Rejected because local edits would create ambiguous authority and drift from the
standards repository.

### Track Mutable main URLs Without Digests

Rejected because reproducibility requires immutable source identity plus expected
bytes.

### Make build Run deps or standards

Rejected because build should remain an offline consumer of prepared state.  The
higher-level `all` target can explicitly compose lifecycle steps without changing
the meaning of `build` itself.

## Consequences

The Makefile gains the Bootstrap-style bashdeps bootstrap and two explicit
manifest lifecycles.  The repository carries synchronized standard files as
reviewable documentation while retaining a machine-verifiable statement of their
upstream bytes.

When `coding_standards` adds or changes a required document, this repository must
intentionally update the immutable URL/digest pin and resynchronize.  Missing
upstream standards cannot be fabricated locally to satisfy the manifest.

## Superseded Decisions

This ADR refines ADR-003 by specifying the Make target and network semantics used
by this product.

This ADR refines ADR-005 and ADR-015.  Their dependency-boundary and attack-surface
principles remain governing; this ADR replaces template-specific dependency
choices with AWK Minifier's actual tools and separates normative standards into a
second manifest.

## Related Decisions

- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-017: Generate ADR Navigation Ephemerally
- ADR-019: Release Artifacts and Bootstrap Minification
