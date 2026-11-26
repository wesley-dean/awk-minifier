# ADR-028: Move Routine Dependency Updates to Centrally Managed Renovate

Date: 2026-11-26

## Status

Accepted

## Decision

This repository SHALL enroll in the centrally managed, Jenkins-hosted Renovate
service through a minimal root `renovate.json`.  Routine GitHub Actions
Dependabot version-update proposals SHALL be disabled by applying
`open-pull-requests-limit: 0` to the existing ecosystem configuration.
The existing ecosystem, root directory, schedule, cooldown, grouping, and
commit conventions SHALL otherwise remain in place for compatibility and
historical transparency.

Dependabot security alerts, vulnerability response, and security update PRs
SHALL remain independent from routine version updates.  The established
`dependabot[bot]`-only non-major auto-merge workflow remains available for
security updates without extending its privileges to Renovate.  Human review,
required checks, code-owner approval, and repository protections SHALL NOT
be bypassed or weakened.

**ADR-028 supersedes ADR-027 as to the active routine-update provider, the
requirement to continue its weekly Dependabot grouping schedule, and its
rejection of a low open-PR limit.**  ADR-027's security-update separation,
risk-aware dependency review, non-major security-PR merge safeguard, and
release trust boundaries remain authoritative where applicable.  The prior
ADR stays in the corpus as the historical decision record.

## Context and Constraints

The existing weekly grouped Dependabot maintenance strategy reduced review
overhead but still duplicated dependency management across the owner's
repositories.  Central Renovate already provides scheduling, update policy,
cryptographically signed commits, and native platform auto-merge governed by
repository protections.  Autodiscovery is not equivalent to accepted machine
account write access; explicit root configuration is required for enrollment.

The repository builds and publishes AWK source artifacts with strict semantic
and portability requirements.  Its previous-release minifier and documentation
dependencies are pinned and verified through bashdeps.  This migration SHALL
NOT alter executable SHA pins, checksum manifests, release behavior, build
network boundaries, or the imported shared coding standards snapshot.

## Assumptions

- The external Jenkins Renovate runner already discovers `wesley-dean/*`.
- The machine account must be granted accepted write access before routine
  updates become operational.
- Repository protection and code-owner approval continue to gate native
  auto-merge.
- GitHub's dependency graph, alerts, and security update settings are
  administered separately and cannot be proven from repository YAML.

## Alternatives Considered

1. **Keep routine Dependabot updates:** duplicates centralized operations;
   rejected.
2. **Delete Dependabot YAML:** loses reviewable policy context and may
   complicate security-update operations; rejected.
3. **Add per-repository Renovate Actions or credentials:** increases secret,
   permission, and maintenance overhead; rejected.
4. **Broaden existing Dependabot auto-merge to Renovate:** could weaken the
   independent machine-identity and approval boundaries; rejected.
5. **Change SHA pins to floating version tags:** would weaken supply-chain
   control; rejected.

## Consequences and Rollout

The migration adds explicit Renovate enrollment, sets a zero limit on
scheduled Dependabot version PRs, and updates the README and decision
summary.  The change does not change AWK runtime transformation, release
artifact identity, compiler/interpreter portability, dependency manifests,
test expectations, or GitHub workflow permissions.

Any `# pin@` annotation may be replaced by a Renovate-compatible release
label only after the exact pinned commit is independently verified against
the upstream tag.  Unknown mappings remain untouched and are recorded as
exceptions.  Every executable SHA remains unchanged.

Existing routine Dependabot PRs SHALL be classified and preserved until
the migration merges and Renovate enrollment is effective; conclusively
routine ones can then be closed with an explanatory migration reference.
Security and ambiguous PRs must not be closed as part of routine cleanup.

Successful configuration merge does not prove an operational Renovate run.
Machine-account permissions, GitHub security settings, required CI and
human approval enforcement must be independently verified.

## Threats and Tradeoffs

The central Renovate account has write-capable automation authority.
Compromised dependencies, signing credentials, or action releases may
affect CI and publishing.  Preserve immutable pins, verified release
metadata, independent advisory response, required reviews and checks,
and a targeted risk assessment for privileged release-path dependencies.
The smallest reviewable repository configuration reduces duplication but
places explicit trust in centrally managed policy and operational health.

## Relationships

- ADR-005, ADR-020, ADR-022, and ADR-024: Pinned build inputs and runtime
  trust boundaries.
- ADR-015 and ADR-016: Security and threat modeling expectations.
- ADR-025 and ADR-026: Managed shared standards and provenance.
- ADR-027: Prior grouped Dependabot strategy, partially superseded.
