# ADR-025: Manage Shared Coding Standards Through GitHub Releases

Date: 2026-09-13

## Status

Accepted

## Context

AWK Minifier consumes shared coding, documentation, repository, Markdown, and ADR
standards maintained in `wesley-dean/coding_standards`.  ADR-020 originally placed
those standards in a second bashdeps manifest, `dependencies-standards.txt`, and
used `make standards` and `make standards-check` to synchronize individually
pinned files beneath `doc/standards/`.

That design proved more complicated than the dependency warrants.  The shared
standards are small text files and examples, while the per-file manifest requires
the consumer to know the upstream file inventory, maintain one URL and digest per
file, and update the manifest when the standards repository adds or removes a
file.  It also makes standards acquisition part of a local network-capable Make
lifecycle even though the repository needs the standards primarily as committed,
reviewable guidance for humans and coding agents.

The standards repository now publishes one deterministic release archive,
`coding-standards.tar.gz`, with a companion SHA-256 file.  The archive contains the
complete `standards/` tree without an outer `standards/` directory so it can be
materialized directly beneath `doc/standards/`.

Coding-agent containers may not have direct GitHub DNS or HTTPS access.  The
consumer therefore cannot require a fresh download before an agent can read the
standards.  The materialized standards must be ordinary tracked repository files.
A network-capable GitHub Actions runner is a better place to perform an explicit,
reviewable update.

The consumer also needs a small source-controlled configuration record describing
which standards release is selected.  A project-root `.env` file is inappropriate
because `.env` is commonly ignored for good security reasons and frequently
contains environment-specific or secret values.  A dedicated tracked
`.codingstandardrc` file gives the standards mechanism an explicit owner and
purpose.

## Decision Drivers

- Keep the selected standards release explicit, pinned, and reviewable.
- Make governing standards available in every ordinary repository checkout.
- Avoid requiring coding-agent containers to contact GitHub before work begins.
- Remove the consumer's need to reproduce the upstream standards file inventory.
- Keep executable dependency acquisition separate from documentation governance.
- Preserve SHA-256 verification before materializing downloaded content.
- Make intentional standards upgrades visible as ordinary repository changes.
- Treat configuration as data rather than executable shell input.

## Decision

AWK Minifier SHALL manage shared coding standards through a manually dispatched
GitHub Actions workflow and a tracked project-root `.codingstandardrc` file.

ADR-025 supersedes only the standards-management portions of ADR-020.  ADR-020
continues to govern bashdeps-managed executable repository tools in
`dependencies.txt`, including `awk-doxygen`, `adrctl`, and the pinned previous
release of AWK Minifier.

### Consumer configuration

The project-root `.codingstandardrc` SHALL contain exactly these managed fields:

```dotenv
CODING_STANDARD_VERSION=vX.Y.Z
CODING_STANDARD_HASH=sha256:<hex-digest>
CODING_STANDARD_URL=https://github.com/wesley-dean/coding_standards/releases/download/vX.Y.Z/coding-standards.tar.gz
CODING_STANDARD_DESTINATION=doc/standards
```

The fields mean:

- `CODING_STANDARD_VERSION` identifies the concrete standards release tag;
- `CODING_STANDARD_HASH` identifies the expected archive bytes and algorithm;
- `CODING_STANDARD_URL` identifies the exact release asset selected for download;
- `CODING_STANDARD_DESTINATION` identifies the repository-relative managed tree.

The file is repository configuration and SHALL be tracked in Git.

The workflow SHALL parse `.codingstandardrc` as data.  It SHALL NOT source or
execute the file as shell code.  Unknown keys, duplicate managed keys, malformed
values, or an unsupported destination SHALL fail closed rather than being
interpreted permissively.

The supported destination for this repository is `doc/standards`.

### Version selection

The update workflow SHALL be triggered manually with `workflow_dispatch` and MAY
receive an optional `version` input.

Version selection follows this precedence:

1. a non-empty manually supplied `version` input;
2. the existing `CODING_STANDARD_VERSION` value in `.codingstandardrc`; or
3. the special request `latest` when no configuration exists or no version is
   recorded.

The workflow input SHALL have no YAML default because the repository's currently
selected version is the normal default after initial bootstrap.

`latest` is a resolution request, not valid committed provenance.  Before
materialization, the workflow SHALL resolve `latest` to a concrete GitHub release
tag.  A committed `.codingstandardrc` SHALL never contain
`CODING_STANDARD_VERSION=latest` or a `/releases/latest/` asset URL.

An explicitly requested concrete version MAY represent an upgrade, downgrade, or
reinstallation.  The workflow does not infer semantic-version ordering policy.

### Configuration-first materialization

Configuration population is the first material step.

After resolving the requested version, the workflow SHALL determine the release
asset URL and published SHA-256 digest, populate a candidate `.codingstandardrc`
with concrete values, then re-read and validate that configuration before
performing the archive download.

This establishes the invariant that the same configuration proposed for commit is
the configuration that drives materialization.  The workflow SHALL NOT populate
`.codingstandardrc` merely as an after-the-fact record of shell variables used by
a separate installation path.

### Download and verification

The workflow SHALL acquire the standards archive from the fixed upstream
repository:

```text
wesley-dean/coding_standards
```

The selected release SHALL provide:

```text
coding-standards.tar.gz
coding-standards.tar.gz.sha256
```

The workflow SHALL verify the downloaded archive against the expected SHA-256
before extracting or replacing tracked standards.  The verified digest SHALL be
recorded in `.codingstandardrc` as `sha256:<hex-digest>`.

The archive SHALL be validated before materialization so absolute paths,
parent-directory traversal, symbolic links, or an unexpected outer `standards/`
prefix cannot expand the extraction boundary.

### Fresh materialization

The workflow SHALL extract the verified archive into a fresh staging directory.
It SHALL NOT overlay a new release onto an existing `doc/standards/` tree because
files removed or renamed upstream could otherwise remain as stale local standards.

Only after release resolution, configuration validation, download, checksum
verification, archive validation, and successful staging may the workflow replace
`doc/standards/`.

The resulting `doc/standards/` tree SHALL be tracked in Git.  It is externally
managed project documentation rather than generated ignored state.

Shared standards SHALL NOT be edited locally.  A shared-standard change belongs in
`wesley-dean/coding_standards`, followed by a released version and an intentional
consumer update.

### Review and repository authority

A standards update SHOULD be proposed through a branch and pull request rather
than written directly to the default branch.  The review surface includes both:

- `.codingstandardrc`, showing the selected concrete version, URL, digest, and
  destination; and
- the exact textual changes beneath `doc/standards/`.

This preserves inspectability while keeping normal development network-free.

### Make and bashdeps boundaries

`dependencies-standards.txt`, `make standards`, and `make standards-check` are
removed.

Make continues to own ordinary build, test, documentation, and executable-tool
dependency orchestration.  Bashdeps continues to manage repository tools declared
in `dependencies.txt`.

Normal `make build`, `make test`, and `make docs` SHALL remain consumers of
prepared local state and SHALL NOT invoke the standards update workflow or contact
the standards repository implicitly.

### Agent and developer access

Developers and coding agents read the committed `doc/standards/` tree from the
normal checkout.  They do not need to execute the update workflow, bashdeps, or a
network bootstrap before the governing standards are available.

`AGENTS.md` SHALL continue to identify the shared standards as governing material
and SHALL direct agents to read the applicable files under `doc/standards/` before
making changes.

## Promises

1. Shared standards are materialized as tracked files beneath `doc/standards/`.
2. `.codingstandardrc` records one concrete standards release and its verified
   archive provenance.
3. Standards updates are explicit, manually initiated repository changes.
4. The downloaded archive is SHA-256 verified before materialization.
5. The updater uses its populated `.codingstandardrc` as the installation input.
6. Normal development and coding-agent startup do not require network access to
   read the standards.
7. Bashdeps remains the executable repository-tool dependency manager and is not
   required for shared standards distribution.

## Non-Promises

1. Receiving the complete standards library does not make every standard
   applicable to AWK Minifier; repository governance determines applicability.
2. The update workflow does not install system packages.
3. The update workflow does not infer whether a newer standards release should be
   adopted automatically.
4. The project does not promise that arbitrary `CODING_STANDARD_DESTINATION`
   values are supported.
5. The standards archive itself is not committed to the repository.
6. A local offline checkout is not required to reconstruct the release archive;
   it is required only to contain the committed materialized standards.

## Considered Alternatives

### Continue per-file bashdeps synchronization

Rejected because the consumer must reproduce the upstream file inventory and
maintain one immutable URL and digest per file.  This is unnecessary bookkeeping
for a small coherent standards library that is already released as one verified
archive.

### Keep `make standards` as a wrapper around the release archive

Rejected because it would retain a local network-capable standards lifecycle even
though the desired steady state is a committed snapshot.  The GitHub Action is the
intentional update boundary; Make remains focused on project orchestration and
prepared local state.

### Use project-root `.env`

Rejected because `.env` is commonly ignored and may contain secrets or
machine-specific configuration.  Standards provenance is safe, tracked repository
configuration and deserves a dedicated file.

### Source `.codingstandardrc` in Bash

Rejected because the workflow runs with repository authority and configuration
should not become an executable-code boundary.  A strict parser keeps the file a
data contract.

### Use a Git submodule

Rejected for this consumer because an ordinary parent-repository checkout does not
guarantee the submodule content is populated.  Coding agents in restricted
containers could therefore receive the repository without its governing standards
and be unable to fetch them directly.

### Continue ignoring `doc/standards/`

Rejected because the central goal is for governing standards to travel with the
repository checkout.  Ignored synchronized state would recreate the network
bootstrap problem.

## Consequences

### Positive

- The standards dependency becomes one release/version/hash rather than many file
  declarations.
- Coding agents receive governing standards in the normal checkout.
- Standards updates produce ordinary Git diffs showing exactly what changed.
- Executable dependency management remains unchanged and narrowly scoped.
- The consumer no longer needs to know the upstream standards file inventory.
- `.codingstandardrc` provides a small, inspectable provenance record.
- The update mechanism can bootstrap a repository from no prior standards
  configuration by resolving `latest` once and persisting the concrete result.

### Negative

- The repository commits derivative standards files and therefore grows modestly.
- A GitHub Actions workflow gains responsibility for repository updates and must be
  reviewed as part of the supply-chain boundary.
- A standards refresh requires a network-capable Actions runner rather than a
  local `make standards` command.
- The full standards library includes language standards that are not applicable
  to this project, trading a small amount of extra text for simpler packaging.

## Compatibility and Migration

Migration from ADR-020's standards model consists of:

1. removing `dependencies-standards.txt`;
2. removing `make standards` and `make standards-check` and their Make variables;
3. removing `doc/standards/` from ignore rules;
4. adding the manual standards-update workflow;
5. running the workflow against a concrete or latest released standards version;
6. committing `.codingstandardrc` and the resulting `doc/standards/` tree; and
7. updating repository documentation and CI references to the old synchronization
   lifecycle.

The executable dependency lifecycle established by ADR-020 remains unchanged.

## Superseded Decisions

ADR-025 supersedes ADR-020 only where ADR-020 requires shared standards to be
listed in `dependencies-standards.txt`, synchronized by bashdeps, ignored as
prepared state, or exposed through `make standards` and `make standards-check`.

ADR-020 remains Accepted for bashdeps-managed executable repository tools and the
explicit network/build boundary associated with those tools.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-020: Bashdeps-Managed Tools and Standards
- ADR-021: AWK Documentation and Portability Testing
