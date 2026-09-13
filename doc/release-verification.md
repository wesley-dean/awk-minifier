# Release Verification

The release pipeline calculates a semantic version from Conventional Commits
without creating a tag, validates the exact bytes intended for publication, and
creates the GitHub release and tag only after validation succeeds.

The expected sequence is:

1. calculate the candidate version with tag creation disabled;
2. validate maintained modular AWK source;
3. synchronize and verify pinned repository tools, including the previous-release
   AWK Minifier;
4. build all three `.awk` artifact flavors with the candidate version;
5. run the public behavior suite against the exact generated artifacts under GNU
   awk and mawk;
6. verify that the `.min.awk` body exactly matches the output produced by the
   pinned v0.1.0 transformer from the current ordinary artifact body;
7. smoke-test every artifact as an AWK program;
8. verify every `.awk.sha256` companion;
9. attest the release artifacts and checksum companions; and
10. create the GitHub release and tag.

Publication is the consequence of successful validation rather than a prerequisite
for it.  A failure before the final release step should therefore leave no new tag.

## Previous-release minification

AWK Minifier v0.1.0 is the first trusted production minifier.  Its ordinary
release artifact is declared in `dependencies.txt` as
`vendor/awk-minifier.awk`, using the v0.1.0 release URL and committed SHA-256
digest:

```text
78dad61b927c2fe96c0e6ddfef75dd1cf395e5572a3e7a54f73622bd29bd58b6
```

`make deps` is the only network-capable path that prepares this dependency.
`make build` remains offline and fails when the prepared transformer is absent.

The production `.min.awk` artifact is derived from the body of the current
ordinary artifact using the pinned v0.1.0 transformer.  The build-owned generated
header is not part of the transformer input because v0.1.0 correctly removes
ordinary comments; instead, the final `.min.awk` receives a fresh provenance
header naming the current version, build date, build commit, and minifier version.

The current candidate remains prohibited as its own production trust root.  A
missing or failing previous-release transformer must fail the build rather than
fall back to copying `.dev.awk`, self-minification, or an unpinned tool.

## Checksums

New releases publish only `.sha256` checksum companions.  Historical release
assets are not rewritten.  The checksum files verify distributed artifact bytes;
they do not replace the committed SHA-256 digests that authorize Bashdeps-managed
repository dependencies.

## Release contents

A normal release contains six files:

```text
awk-minifier.dev.awk
awk-minifier.dev.awk.sha256
awk-minifier.awk
awk-minifier.awk.sha256
awk-minifier.min.awk
awk-minifier.min.awk.sha256
```

All three executable artifacts must satisfy the same public source-transformation
contract even when their representation differs.
