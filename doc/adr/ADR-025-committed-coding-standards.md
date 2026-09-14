# ADR-025: Commit Shared Coding Standards as Repository Content

Date: 2026-09-13

## Status

Accepted

## Context

AWK Minifier consumes shared coding, documentation, and engineering standards
maintained in `wesley-dean/coding_standards`.  Those standards must be available
to human maintainers and coding agents before implementation work begins.

ADR-020 originally modeled the standards as a second dependency lifecycle.  It
used `dependencies-standards.txt`, `make standards`, and `make standards-check`
to synchronize individually pinned files beneath `doc/standards/`.  A later
experiment replaced that mechanism with a dedicated `.codingstandardrc` file and
a manually dispatched GitHub Actions workflow that downloaded a standards archive
and materialized the tree.

Both approaches solved the same underlying problem: getting standards into the
consumer repository.  Neither mechanism is necessary for this project.

The standards are small text files and examples.  The important property is that
the governing material is present in an ordinary checkout, inspectable in the
same pull request as any update, and usable by restricted coding-agent containers
without a network bootstrap.  Git already provides the review, history, and
snapshot semantics needed once those files are committed.

The normal maintenance model also permits an authorized maintainer or coding
agent with GitHub repository access to copy the current upstream `standards/`
tree into `doc/standards/` and open a pull request directly.  Reproducing that
operation inside every consumer repository adds code, configuration, credentials,
and supply-chain surface without materially improving the resulting reviewable
state.

## Decision Drivers

- Make the governing standards available in every ordinary checkout.
- Keep standards changes visible as normal Git diffs.
- Avoid requiring local or agent environments to contact GitHub before work can
  begin.
- Avoid consumer-side machinery whose only purpose is copying documentation.
- Keep executable dependency management separate from repository governance.
- Preserve one canonical upstream for shared standards.
- Prefer repository history and pull-request review over additional provenance
  files when the committed files themselves are the consumed artifact.
- Minimize CI authority, credentials, scripts, configuration, and dependency
  surface.

## Decision

AWK Minifier SHALL commit the complete contents of the canonical
`wesley-dean/coding_standards` `standards/` directory beneath:

```text
doc/standards/
```

The upstream hierarchy SHALL be preserved.  For example:

```text
coding_standards/standards/awk/documentation-standard.md
```

is materialized as:

```text
awk-minifier/doc/standards/awk/documentation-standard.md
```

The complete standards tree is committed even when some language-specific files
do not apply to AWK Minifier.  Applicability is a repository-governance concern,
not a packaging concern.

### Canonical authority

`wesley-dean/coding_standards` remains the canonical source for shared standards.
Files beneath `doc/standards/` are committed snapshots for this repository; they
are not an independent fork.

A shared-standard change SHALL be made upstream first.  AWK Minifier adopts the
result through an intentional repository change that replaces or updates the
corresponding committed snapshot.

Repository-specific governance may refine applicability or add project-specific
requirements without editing the imported shared text.

### Update mechanism

AWK Minifier SHALL NOT contain a dedicated standards-fetching or
standards-synchronization mechanism.

In particular, the repository SHALL NOT require any of the following merely to
maintain `doc/standards/`:

- `dependencies-standards.txt`;
- `make standards`;
- `make standards-check`;
- `.codingstandardrc`;
- a standards-download script;
- a standards-update GitHub Actions workflow;
- a release-archive extraction contract; or
- a consumer-side checksum manifest for the standards snapshot.

A standards refresh is an ordinary repository maintenance operation.  An
authorized maintainer or coding agent may obtain the desired upstream
`standards/` tree, replace the committed `doc/standards/` snapshot while
preserving its hierarchy, review the resulting diff, and propose the change
through the normal branch and pull-request process.

The mechanism used by a maintainer to read the upstream repository is outside the
AWK Minifier architecture.  GitHub UI, GitHub API access, a Git client, or an
authorized coding agent are all acceptable ways to obtain the source material;
none becomes a required project dependency or workflow.

### Repository checkout contract

`doc/standards/` SHALL be tracked Git content and SHALL NOT be ignored as generated
or prepared state.

Normal build, test, and documentation targets SHALL consume the checkout as-is and
SHALL NOT acquire or refresh standards implicitly.

Coding agents and human contributors SHALL read the applicable committed
standards before making changes.  `AGENTS.md` identifies the applicable standards
and repository governance remains authoritative when determining applicability.

### Provenance

No additional consumer-side provenance file is required.

The repository commit containing `doc/standards/` is the reviewed snapshot that
AWK Minifier consumes.  Pull-request history provides the adoption record and the
upstream repository provides the canonical history of each shared standard.

When useful, a standards-refresh pull request may identify the upstream commit or
release from which the snapshot was copied, but AWK Minifier does not require a
persistent `.codingstandardrc`, archive hash, or download URL to function.

This decision does not prohibit a future provenance mechanism if a concrete
operational or compliance requirement emerges.  Such a mechanism would require a
new or superseding architectural decision rather than being introduced as hidden
update machinery.

### Bashdeps and Make boundaries

ADR-020 remains governing for executable repository tools managed through
`dependencies.txt` and bashdeps.

Shared standards are not executable dependencies and do not participate in the
bashdeps lifecycle.  GNU Make remains the canonical project orchestration surface
for build, test, documentation, and executable dependency preparation; it does
not own standards synchronization.

## Promises

1. The complete shared standards snapshot is committed beneath `doc/standards/`.
2. An ordinary checkout contains the standards needed by humans and coding agents.
3. The imported directory hierarchy matches the upstream `standards/` hierarchy.
4. Shared standards remain canonically maintained in
   `wesley-dean/coding_standards`.
5. Standards updates are explicit, reviewable repository changes.
6. Normal build, test, and documentation operations do not acquire standards from
   the network.
7. AWK Minifier contains no dedicated standards-fetching machinery.
8. Bashdeps remains scoped to executable repository dependencies.

## Non-Promises

1. Committing the complete standards library does not make every standard
   applicable to AWK Minifier.
2. AWK Minifier does not automatically detect or adopt newer upstream standards.
3. The repository does not promise a particular external tool or agent for
   performing a standards refresh.
4. The consumer repository does not independently verify an upstream archive at
   runtime or build time.
5. The committed snapshot is not an independent fork whose shared text should be
   edited locally.
6. The standards snapshot does not replace project-specific ADRs, `AGENTS.md`, or
   other repository governance.

## Considered Alternatives

### Per-file bashdeps synchronization

Rejected because it requires a second manifest, per-file URLs and digests,
network-capable Make targets, and consumer knowledge of the upstream file
inventory.  Those mechanisms add maintenance surface without improving access to
already committed text.

### Consumer-side GitHub Actions updater

Rejected after prototyping.  A workflow can download, verify, and materialize the
standards, but persisting the result requires repository write authority and often
additional credentials.  The workflow duplicates an operation an authorized
maintainer or coding agent can already perform directly through GitHub while
adding configuration, parsing logic, archive handling, CI authority, and another
security boundary.

### `.codingstandardrc`

Rejected because its primary purpose was to drive or record the consumer-side
updater.  Once the updater is removed, the committed standards files and Git
history are the state the project actually consumes.  Keeping a separate config
file would create another value that can drift without supplying a current
requirement.

### Release archives and checksum sidecars in the consumer workflow

Rejected as a consumer requirement.  Release packaging may still be useful to
other `coding_standards` consumers, but AWK Minifier does not need to implement or
understand that packaging contract merely to commit shared Markdown and example
files.

### Git submodule

Rejected because an ordinary parent-repository checkout does not guarantee that
submodule content is populated.  Restricted coding-agent environments could then
receive the project without its governing standards and lack the network access
needed to initialize the submodule.

### Ignore `doc/standards/` and fetch on demand

Rejected because the entire reason to materialize standards in the consumer is to
make governance available before work begins, including in restricted or offline
environments.

### Maintain local copies independently

Rejected because it creates competing authorities and makes shared improvements
harder to propagate consistently.  The imported files remain copies of the
canonical `coding_standards` material.

## Consequences

### Positive

- The consumer architecture becomes substantially smaller.
- Every checkout contains the governing shared material.
- Standards updates are visible as ordinary textual Git diffs.
- No consumer workflow needs repository write authority merely to refresh docs.
- No extra config parser, archive validator, downloader, or checksum lifecycle is
  maintained in AWK Minifier.
- Coding-agent operation does not depend on GitHub network access at task time.
- Executable dependency management remains focused on executable dependencies.

### Negative

- Refreshing the standards is a maintainer operation rather than a repository
  command.
- The repository commits derivative copies of the shared standards and therefore
  grows modestly.
- There is no automatic alert or built-in command indicating that a newer upstream
  snapshot exists.
- A maintainer must take care to replace the full snapshot rather than partially
  updating selected files when the intent is to adopt the complete current tree.

These costs are accepted because they are smaller than the permanent machinery
required to automate a low-frequency documentation-copy operation.

## Compatibility and Migration

Migration from ADR-020's original standards lifecycle and the later updater
prototype consists of:

1. removing `dependencies-standards.txt`;
2. removing `make standards`, `make standards-check`, and their Make variables;
3. ensuring `doc/standards/` is not ignored;
4. removing `.codingstandardrc` if it exists;
5. removing standards-download or update workflows and scripts;
6. committing the complete current upstream `standards/` tree beneath
   `doc/standards/`;
7. removing CI steps that synchronize standards during ordinary testing; and
8. updating repository documentation to describe the committed-snapshot model.

The executable dependency lifecycle established by ADR-020 remains unchanged.

## Superseded Decisions

ADR-025 supersedes ADR-020 only where ADR-020 requires shared standards to be
listed in `dependencies-standards.txt`, synchronized by bashdeps, ignored as
prepared state, or exposed through `make standards` and `make standards-check`.

It also supersedes the unmerged updater prototype that introduced
`.codingstandardrc` and a manually dispatched standards-update workflow.  That
prototype is retained only in Git history and is not part of the repository's
accepted operating model.

ADR-020 remains Accepted for bashdeps-managed executable repository tools and the
explicit network/build boundary associated with those tools.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-020: Bashdeps-Managed Tools and Standards
- ADR-021: AWK Documentation and Portability Testing
