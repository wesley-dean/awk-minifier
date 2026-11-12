# ADR-027: Consolidate GitHub Actions Dependabot Maintenance

Date: 2026-11-12

## Status

Accepted

## Context

AWK Minifier uses a weekly Dependabot schedule and a seven-day cooldown for
GitHub Actions.  Its existing `minor-and-patch` group excludes major updates,
so related scheduled upgrades can arrive as several independently reviewed PRs.
Across multiple maintained repositories this causes repeated review and merge
overhead.  The new v3.2.0 shared standards snapshot includes a consolidated
Dependabot maintenance standard.

The repository builds multiple externally distributed executable AWK artifacts
and checks the ordinary/minified products against a pinned previous release.
An action used to build, publish, sign, or upload products can exercise broader
privileges than a read-only test.  Relevant release-path evidence remains
necessary for changes to those actions.

The active Dependabot auto-merge workflow already excludes updates whose
highest semantic version change is major, using
`dependabot/fetch-metadata`.  GitHub branch protections and effective CODEOWNER
approval remain independent settings not established by the presence of a
CODEOWNERS file.

## Decision Drivers

- Reduce repeated routine PR review without hiding dependency changes.
- Retain weekly scheduling, seven-day cooldown, and existing commit conventions.
- Preserve independent prompt response to security advisories.
- Keep existing major-update review and repository permissions unchanged.
- Demand relevant evidence for high-authority publishing and build actions.
- Preserve the project's pinned previous-release minification trust boundary.
- Avoid arbitrarily suppressing new PRs with restrictive open-PR limits.

## Decision

The GitHub Actions Dependabot ecosystem SHALL continue using the repository
root directory, weekly schedule, existing seven-day cooldown, and existing
commit-message conventions.  One group named `actions-version-updates` SHALL
use `applies-to: version-updates`, `patterns: ["*"]`, and no
`update-types` restriction.  Eligible scheduled major, minor, and patch
version updates therefore can be grouped.

Security updates SHALL remain outside this routine group.  GitHub's
dependency graph, alerting, and automatic security-update settings must
be verified separately; this change does not enable them or promise their
timing.  No low `open-pull-requests-limit` is introduced.

The existing Dependabot auto-merge guard excluding
`version-update:semver-major` SHALL remain unchanged.  A group containing a
major update is expected to require ordinary review.  The effective required
checks, CODEOWNERS enforcement, and repository permissions must remain
independent of grouping.

Maintainers SHALL inspect the highest-risk update in each group, particularly
actions capable of running external code, writing repository contents,
accessing credentials, creating releases, or uploading executable artifacts.
Passing unrelated unit tests is insufficient evidence for an unexercised
release workflow.  Individual risky dependencies MAY be isolated into
separate groups with an explicit documented reason and periodic review.

Existing open Dependabot PRs SHALL NOT be closed solely because this
configuration changed.  A later actual grouped PR must be inspected before
asserting it supersedes their changes.  Grouping does not guarantee exactly
one PR per week, uniform mixed-major behavior, or compatibility of dependencies.

## Alternatives Considered

### Retain minor/patch grouping and separate major PRs

Retains simpler review units but perpetuates avoidable repeated work.
Rejected as the default; narrowly scoped exceptions remain possible.

### Automatically merge grouped major updates

Would reduce review operations but could admit breaking or privileged action
updates without sufficient validation.  Rejected.

### Delay security updates inside the weekly group

Would conflate vulnerability remediation with optional maintenance and may
delay urgent fixes.  Rejected.

### Impose a low open-PR limit

Could suppress new updates when existing PRs remain open.  Deferred until
operational evidence supports a limit.

### Switch immediately to monthly schedules or cross-ecosystem groups

Changes update latency and widens risk grouping beyond the present scope.
Rejected for this adoption.

## Threats and Tradeoffs

Larger groups can obscure a problematic dependency or combine a breaking
release with otherwise harmless upgrades.  Compromised external actions
can misuse workflow permissions.  Green checks do not necessarily cover
release and artifact-publishing paths.  A CODEOWNERS file is not proof of
effective approval enforcement, and disabled security automation is a
separate issue.

Mitigations are human review of the highest-risk changes, retained pinned
action revisions, independent GitHub protections, non-major auto-merge
boundaries, and targeted release-path validation.  These controls reduce,
rather than eliminate, supply-chain risk.

The expected outcome is fewer routine PR reviews, at the cost of sometimes
larger grouped diffs and a need to isolate rare high-risk updates.  Actual
PR-volume reduction remains an observation to measure after rollout.

## Compatibility and Migration

The only active configuration change is scheduled GitHub Actions Dependabot
version-update grouping.  No AWK runtime transformations, public interface,
interpreter portability baseline, Make build target, pinned minifier,
generated release artifact, checksum, or workflow permission is altered.

Existing open Dependabot PRs remain and may be reconciled after a subsequent
verified grouped update.  The historical ADR record stays intact.

## Relationships

ADRs 018-024 establish portable AWK source assembly, verified release
flavors, pinned build dependencies, documentation, and previous-release
minification.  ADRs 025-026 govern adoption and provenance of the immutable
standards snapshot.  This decision applies the new shared v3.2.0
Dependabot maintenance standard within those local boundaries.
