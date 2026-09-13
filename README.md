# AWK Minifier

AWK Minifier is a conservative source-to-source transformer for AWK programs.  It
reads AWK source from standard input and writes a smaller representation to
standard output while preserving program meaning as the primary requirement.

The implementation is itself portable AWK.  It does not require a Bash runtime,
and maintained source can be executed directly as an ordered set of `awk -f`
modules or assembled into standalone release artifacts.

## Current transformation policy

The first implementation deliberately favors safety over maximum compression.  It:

- removes comments only when they are outside string and regexp literals;
- collapses horizontal whitespace outside literals when a separator is still
  required;
- preserves physical newlines rather than attempting broad statement joining;
- distinguishes regexp delimiters from division and `/=` using lexical context;
- preserves string and regexp contents byte-for-byte while scanning escapes;
- preserves a first-line AWK shebang;
- buffers transformed output until the complete input has been validated; and
- fails nonzero with a diagnostic on STDERR when a string or regexp literal is
  unterminated.

The project does not claim that this first implementation is a complete AWK parser
or that it produces the smallest possible output.  When the transformer cannot
safely prove that a more aggressive rewrite preserves meaning, the conservative
representation wins.

## Usage

A release artifact reads AWK source from STDIN and writes transformed AWK source
to STDOUT:

```bash
awk -f dist/awk-minifier.awk < input.awk > output.awk
```

The maintained modular source is directly executable in the same way:

```bash
awk \
  -f src/diagnostics.awk \
  -f src/output.awk \
  -f src/lexer.awk \
  -f src/main.awk \
  < input.awk > output.awk
```

Diagnostics are written to STDERR.  Exit status zero means the complete input was
transformed successfully.  On a transformation error, transformed output is not
published as a partial successful result.

## Release artifacts

`make build` creates three standalone artifacts and one adjacent `.sha256` file
for each:

- `dist/awk-minifier.dev.awk` contains the assembled maintained source and its
  documentation;
- `dist/awk-minifier.awk` removes only project-governed Doxygen documentation
  lines; and
- `dist/awk-minifier.min.awk` contains the ordinary artifact body transformed by
  the pinned AWK Minifier v0.1.0 release.

The v0.1.0 release is the first trusted production minifier and is synchronized by
Bashdeps as `vendor/awk-minifier.awk`.  The generated provenance header remains
outside the transformer input so the final minified artifact still identifies its
version, build date, build commit, and minifier version.  The current release
candidate is never used as its own production trust root.

## Building and testing

GNU Make is the canonical orchestration interface.  Prepare repository tools
before building:

```bash
make deps
make deps-check
make build
make check
make test
```

`make all` is the convenience lifecycle that runs dependency preparation followed
by the build.

`make build` itself is network-free and never repairs dependency state.  It now
requires the prepared `vendor/awk-minifier.awk` dependency because steady-state
`.min.awk` construction uses the pinned previous release.

The test harness accepts an explicit interpreter:

```bash
make test AWK_BIN=mawk
make test AWK_BIN=gawk
```

Tests cover modular source and all assembled artifacts, exact transformations,
semantic equivalence, malformed-input failure behavior, regexp/division
classification, continuation handling, and idempotence.

## Repository dependencies

The Makefile follows the dependency model used by
[`wesley-dean/bootstrap`](https://github.com/wesley-dean/bootstrap): Make directly
bootstraps only a pinned `bashdeps.bash`.  Bashdeps then manages other
repository-scoped tools declared in `dependencies.txt`.

```bash
make deps        # may access the network and converge vendor state
make deps-check  # offline verification; does not repair state
```

The tool manifest includes the released `awk-doxygen` filter, `adrctl`, and AWK
Minifier v0.1.0.  The v0.1.0 ordinary release artifact is pinned by immutable
release URL and SHA-256 digest and is used only as the previous-release production
transformer.

System packages such as `awk`, `make`, and `doxygen` are not installed by
Bashdeps.

## Shared standards

Normative shared standards are synchronized separately from executable tools:

```bash
make standards        # may access the network
make standards-check  # offline verification; does not repair state
```

`dependencies-standards.txt` maps pinned files from
[`wesley-dean/coding_standards`](https://github.com/wesley-dean/coding_standards)
into `doc/standards/`, preserving their upstream hierarchy.  Imported standards
and examples are synchronized copies and should not be edited locally.

Standards that do not yet exist upstream are not fabricated in this repository;
they can be added to the manifest after they exist in `coding_standards` and can
be pinned to immutable bytes.

## Documentation

Maintained AWK source follows the shared AWK documentation standard and uses
`awk-doxygen` for Doxygen input filtering.

After repository dependencies have been prepared:

```bash
make docs
```

Documentation generation is deliberately offline.  It consumes the already
prepared `vendor/doxygen-awk.awk` and `vendor/adrctl.bash` artifacts, generates the
ephemeral ADR landing page, and writes Doxygen output under `doc/reference/`.

The architectural decision map is maintained in
[`doc/decisions.md`](doc/decisions.md).  Accepted ADRs under `doc/adr/` govern the
implementation when a shorter repository document appears to conflict with them.

## Portability

The product targets portable AWK rather than GNU AWK extensions.  CI exercises
multiple implementations so an implementation-specific assumption is less likely
to become an accidental contract.

The current POSIX language baseline is the AWK utility described by POSIX.1-2024.
Repository ADRs and tests remain the project's concrete compatibility contract.

## License

See [LICENSE](LICENSE).
