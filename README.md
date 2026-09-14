# AWK Minifier

AWK Minifier is a conservative source-to-source transformer for AWK programs.  It
reads AWK source from standard input and writes a smaller representation to
standard output while preserving program meaning as the primary requirement.

The implementation is itself portable AWK.  It does not require a Bash runtime,
and maintained source can be executed directly as an ordered set of `awk -f`
modules or assembled into standalone release artifacts.

## Current transformation policy

The transformer deliberately favors semantic safety over maximum compression.  It:

- removes comments only when they are outside string and regexp literals;
- collapses horizontal whitespace outside literals when a separator is still
  required;
- classifies physical newlines using AWK grammar context, discarding
  grammar-optional newlines and rendering statement or rule terminators as `;`;
- removes explicit backslash-newline continuations between source tokens without
  creating statement boundaries;
- rejects backslash-newline inside string or regexp literals because the supported
  AWK implementations do not agree on that source construct's semantics;
- distinguishes regexp delimiters from division and `/=` using lexical context;
- preserves accepted string and regexp contents byte-for-byte while scanning
  escapes;
- preserves a first-line AWK shebang and its terminating newline;
- buffers transformed output until the complete input has been validated; and
- fails nonzero with a diagnostic on STDERR for malformed or explicitly rejected
  non-portable literal input.

For successful portable-AWK input, transformed source contains exactly one
physical newline when a first-line shebang is preserved and zero physical newlines
otherwise.  AWK newlines are not treated as generic whitespace: true statement or
rule boundaries become semicolons, while grammar-optional newlines disappear.

The project does not claim that the implementation is a complete AWK parser or
that it produces the smallest possible byte representation.  When the transformer
cannot safely prove that a more aggressive rewrite preserves meaning across the
supported portability floor, it fails conservatively rather than selecting one
implementation's interpretation.

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
  -f src/context.awk \
  -f src/lexer.awk \
  -f src/transform.awk \
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
  the pinned AWK Minifier v0.2.1 release.

The v0.2.1 release is the current trusted production minifier and is synchronized
by Bashdeps as `vendor/awk-minifier.awk`.  The generated provenance header remains
outside the transformer input so the final minified artifact still identifies its
version, build date, build commit, and minifier version.  The current release
candidate is never used as its own production trust root.

Because v0.2.1 implements ADR-023's grammar-aware newline elimination, production
`.min.awk` bodies now use the same zero-or-one-physical-newline representation
contract as the released transformer itself.

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
classification, grammar-aware newline elimination, control-flow continuation,
portable explicit continuation between tokens, rejection of non-portable
literal-internal continuation, physical-line invariants, candidate
self-minification, and idempotence.

## Repository dependencies

The Makefile follows the dependency model used by
[`wesley-dean/bootstrap`](https://github.com/wesley-dean/bootstrap): Make directly
bootstraps only a pinned `bashdeps.bash`.  Bashdeps then manages executable
repository-scoped tools declared in `dependencies.txt`.

```bash
make deps        # may access the network and converge vendor state
make deps-check  # offline verification; does not repair state
```

The tool manifest includes the released `awk-doxygen` filter, `adrctl`, and AWK
Minifier v0.2.1.  The v0.2.1 ordinary release artifact is pinned by immutable
release URL and SHA-256 digest and is used only as the previous-release production
transformer.

System packages such as `awk`, `make`, and `doxygen` are not installed by
Bashdeps.

## Shared standards

The complete shared standards library from
[`wesley-dean/coding_standards`](https://github.com/wesley-dean/coding_standards)
is committed beneath `doc/standards/`, preserving the upstream `standards/`
directory hierarchy.

The project-root `.codingstandardrc` records the concrete released standards
version, the SHA-256 digest of its `coding_standards.tar.gz` release artifact, the
canonical source repository, and the managed destination.  The current snapshot is
`coding_standards@v1.0.3`.

These files are ordinary tracked repository content so developers and coding
agents can read the governing standards from a normal checkout without a network
bootstrap.  AWK Minifier contains no standards downloader, synchronization Make
target, standards dependency manifest, or standards-update GitHub Actions
workflow.

Files beneath `doc/standards/` are governing project requirements, not suggestions.
Apply every relevant standard unless an accepted repository-specific ADR or
explicit project policy supersedes or refines it.  Do not silently deviate from an
applicable standard.

Imported standards are externally maintained copies and must not be edited
locally.  Shared changes belong in `coding_standards`; adopting another release is
an intentional repository maintenance change that replaces the complete managed
`doc/standards/` tree, updates `.codingstandardrc`, and is reviewed through the
normal pull-request process.

Receiving the complete library does not make every language-specific standard
applicable to AWK Minifier.  General and cross-cutting standards apply where
relevant.  The AWK standards apply to maintained AWK source.  Other language
standards apply only when their subject matter is relevant.  Content under
`examples/` is illustrative and non-normative unless a governing standard states
otherwise.

See ADR-025 for the committed-snapshot rationale and ADR-026 for the versioned
provenance and governance contract.

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
