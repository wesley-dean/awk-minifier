# ADR-018: Portable AWK Runtime and Explicit Source Assembly

Date: 2026-09-12

## Status

Accepted

## Context

The repository was created from template-bash and therefore inherited a Bash
runtime baseline, Bash source files, and an executable plugin example.  Issue #2
changes the product itself: AWK Minifier is an AWK source transformer whose
maintained implementation must be written in portable AWK and whose public input
and output are AWK source text.

The implementation guide requires modular maintained source, direct execution of
that source through repeated `awk -f` arguments, deterministic standalone
assembly, and conservative behavior when lexical or syntactic context is
uncertain.  The earlier template decisions remain useful where they describe
explicit ordering and deterministic assembly, but a Bash runtime and automatically
discovered runtime plugins no longer describe this product.

## Decision Drivers

- The minifier should run on common POSIX-family AWK implementations.
- Maintained source should remain decomposed by responsibility and reviewable.
- Source ordering must be explicit rather than filesystem-discovery dependent.
- The maintained modular source and assembled development artifact must express
  the same behavior.
- The transformer must favor semantic preservation over maximal compression.
- Runtime extension machinery should not survive merely because it existed in the
  starter repository.

## Decision

AWK Minifier SHALL be implemented in portable AWK.  The implementation SHALL NOT
require GNU AWK extensions unless a later ADR deliberately changes the portability
baseline.

Maintained product source SHALL live under `src/` as responsibility-focused AWK
modules.  The Makefile SHALL own an explicit ordered source list.  Maintained
source MUST be directly runnable by invoking the selected interpreter with the
modules in that same order, for example:

```text
awk -f src/constants.awk -f src/diagnostics.awk ... -f src/main.awk
```

Standalone artifacts SHALL be assembled deterministically from that explicit
ordered list.  Filesystem glob ordering, runtime plugin discovery, dynamic
loading, and registration machinery are not part of the AWK Minifier runtime
architecture.

The public transformer contract is:

- AWK source is read from standard input;
- transformed AWK source is written to standard output;
- diagnostics are written to standard error;
- exit status zero means the complete input was transformed successfully; and
- on a transformation error, the process MUST NOT present partial transformed
  output as a successful result.

The implementation SHALL use lexical state plus contextual recognition rather
than regular-expression substitution over raw lines.  Whitespace, comments, and
newlines that separate tokens SHALL be treated as a pending gap whose final
representation is decided only when enough context is available.  If the
implementation cannot prove that deleting or rewriting a gap is safe, it SHALL
preserve the conservative representation or reject the transformation rather than
silently change program meaning.

Slash classification SHALL be contextual.  A slash MUST NOT be classified as a
regular-expression delimiter or division operator solely from its character
value.  The recognizer SHALL track whether a primary expression is legal at the
current position and use that context to distinguish regexp literals from division
and assignment operators.

## Promises

1. The maintained product implementation is AWK, not a Bash wrapper around AWK.
2. Maintained modules are executable directly using repeated `awk -f` arguments.
3. Standalone assembly order is explicit and deterministic.
4. Runtime plugins and dynamic source discovery are not required architecture.
5. Conservative semantic preservation takes priority over shrinking every byte.
6. Standard input, standard output, standard error, and exit status form the
   stable command contract.

## Non-Promises

1. The first implementation does not promise the smallest possible minified AWK.
2. The project does not promise GNU AWK-specific syntax or APIs.
3. The project does not promise recovery from malformed AWK input.
4. Explicit modular source does not imply independently loadable runtime plugins.

## Considered Alternatives

### Keep Bash as the Product Runtime

Rejected.  Bash may remain build and test orchestration glue, but making the
transformer itself a Bash program contradicts the product contract and would add a
runtime dependency that the AWK implementation does not require.

### Port the Bash Minifier Character Scanner Directly

Rejected.  Prior Bash-minifier work is useful evidence about quoting, escaping,
and continuation hazards, but AWK has different token and grammar ambiguities,
most notably slash classification and newline significance.  The architecture
must model AWK rather than mechanically translate Bash rules.

### Use Regex-Only Line Rewriting

Rejected because comments, string literals, regexp literals, division operators,
continuations, and newline-sensitive grammar cannot be handled reliably by blind
line substitutions.

### Preserve Runtime Plugin Discovery

Rejected because the minifier does not presently require runtime extensibility.
The useful reusable invariant is modular maintained source plus deterministic
assembly, not the starter's plugin mechanism.

## Consequences

The inherited Bash product source and plugin example will be removed.  Build and
CI shell code may remain where shell orchestration is appropriate, but product
behavior and source documentation move to AWK.

Testing must exercise both the modular repeated-`-f` form and assembled release
artifacts so divergence in source order or assembly becomes observable.

## Superseded Decisions

This ADR supersedes ADR-002's Bash runtime and portability baseline for the AWK
Minifier product.

This ADR supersedes the automatically discovered runtime-plugin portion of
ADR-004.  It preserves and strengthens ADR-004's explicit core source ordering.

This ADR refines ADR-014: responsibility-focused maintained source,
deterministic assembly, and standalone consumer artifacts remain governing
principles, while runtime registries and noop plugins are not used by this
product.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-004: Modular Source Assembly and Automatically Discovered Plugins
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-014: Modularity as Maintenance and Assembly Architecture
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
