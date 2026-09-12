# Release Verification

The release pipeline calculates a semantic version from Conventional Commits
without creating a tag, validates the exact bytes intended for publication, and
creates the GitHub release and tag only after validation succeeds.

The expected sequence is:

1. calculate the candidate version with tag creation disabled;
2. validate maintained modular AWK source;
3. synchronize and verify pinned repository tools;
4. build all three `.awk` artifact flavors with the candidate version;
5. run the public behavior suite against the exact generated artifacts under GNU
   awk and mawk;
6. verify the bootstrap lineage rule that `.min.awk` equals `.dev.awk` until a
   prior released transformer is intentionally pinned;
7. smoke-test every artifact as an AWK program;
8. verify every `.awk.sha256` companion;
9. attest the release artifacts and checksum companions; and
10. create the GitHub release and tag.

Publication is the consequence of successful validation rather than a prerequisite
for it.  A failure before the final release step should therefore leave no new tag.

## Bootstrap minification

The initial AWK Minifier release line does not pretend to possess a prior trusted
AWK Minifier.  Its `awk-minifier.min.awk` is intentionally an exact copy of
`awk-minifier.dev.awk`.

After a trustworthy released version exists, a later accepted change may add that
immutable released artifact to `dependencies.txt` and use it as
`vendor/awk-minifier.awk` to transform subsequent production `.min.awk` artifacts.
The current candidate remains prohibited as its own production trust root.

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
