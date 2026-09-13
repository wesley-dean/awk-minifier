# Contributing to AWK Minifier

Thank you for contributing.

Before proposing changes, read `README.md`, `AGENTS.md`, `doc/decisions.md`, and
the ADRs relevant to the area being changed.  Accepted ADRs define the current
architecture and should not be silently contradicted by an implementation change.

## Development workflow

Maintained product code is portable AWK.  Build and repository orchestration may
use Bash and GNU Make.

Prepare repository-scoped tools before building:

```bash
make deps
make deps-check
```

Typical local validation is then:

```bash
make build
make check
make test
```

`make all` is available when dependency convergence followed by a build is the
desired lifecycle.

When multiple AWK implementations are available, run the suite against them:

```bash
make test AWK_BIN=mawk
make test AWK_BIN=gawk
```

Shared standards use their own lifecycle:

```bash
make standards
make standards-check
```

Do not make `build`, `test`, or `docs` silently acquire dependencies.

## Source documentation

Maintained AWK follows the shared AWK documentation standard synchronized from
`wesley-dean/coding_standards`.  Public and maintained source contracts should be
captured in `##` Doxygen blocks compatible with `awk-doxygen`.

## Testing expectations

A behavioral change should include evidence appropriate to its risk.  For source
transformation behavior this normally means both focused exact-output fixtures and
semantic-equivalence tests.

Please include regression coverage for changes involving:

- comments or whitespace;
- string or regexp literal escaping;
- slash classification;
- division or `/=`;
- physical newlines or continuations;
- control-flow and function-definition line breaks;
- top-level rule separation;
- malformed input and diagnostics; or
- differences among modular and assembled artifact forms.

ADR-023 makes physical line count an explicit minification invariant.  Successful
output has one newline only when preserving a first-line shebang and otherwise has
none.  Newline changes should demonstrate statement/rule separator insertion,
grammar-optional newline removal, semantic equivalence, idempotence, and
portability rather than relying on visual inspection of compressed output.

The current candidate must never be used as its own production minification trust
root.  Production `.min.awk` artifacts are built with the Bashdeps-pinned AWK
Minifier v0.2.1 release.  Candidate self-minification is test evidence only.
Build-pipeline changes should preserve explicit previous-release lineage and fail
rather than silently substituting another transformer.

## Commits and pull requests

Use Conventional Commit titles so release automation can determine semantic
version impact.  Keep pull requests cohesive and avoid unrelated cleanup.

A consequential change to architecture, public behavior, compatibility, security
boundaries, dependency trust, or release provenance may require a new or updated
ADR.  When ADRs change, update `doc/decisions.md` as part of the same pull request.
