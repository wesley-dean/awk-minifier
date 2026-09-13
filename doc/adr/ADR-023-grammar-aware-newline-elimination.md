# ADR-023: Grammar-Aware Newline Elimination

Date: 2026-09-12

## Status

Accepted

## Context

AWK Minifier v0.1.0 deliberately preserved physical newlines.  That choice made
the first implementation conservative, but it also left a large amount of
structural whitespace in otherwise minified output.  Minifying the project's own
development artifact demonstrates the gap clearly: comments and horizontal
whitespace shrink, while hundreds of physical newlines remain.

AWK newlines cannot safely be deleted as ordinary whitespace.  The AWK grammar
uses NEWLINE both as a statement or rule terminator and in grammar positions where
a newline is optional.  A blind rewrite can therefore change control flow, merge
rules, create an empty loop body, or otherwise produce different valid source.

The POSIX AWK grammar provides enough structure to make the distinction explicit.
Statements and top-level items can use newline or semicolon terminators.  Newlines
are optional in specific grammatical contexts, including after an opening brace,
a comma, logical `&&` or `||`, `do`, `else`, and the closing parenthesis of an
`if`, `for`, or ordinary `while` header.  Function definitions permit optional
newlines between the parameter-list closing parenthesis and the action.  Nested
actions are themselves terminated statements.  A backslash immediately followed
by a newline has no lexical effect.

`do ... while` requires additional context.  The closing parenthesis of an
ordinary `while` header can be followed by an optional newline before its body,
while the closing parenthesis of the trailing `while` in a `do ... while`
statement completes the statement and therefore requires a terminator before a
following sibling statement.  Treating those cases alike would change meaning.

## Decision Drivers

- Make newline removal a grammar-aware transformation rather than a textual
  cleanup pass.
- Preserve AWK program meaning ahead of byte reduction.
- Produce genuinely compact output with a stable, testable physical-line
  invariant.
- Preserve the first-line shebang contract.
- Remain within the portable AWK runtime baseline established by ADR-018.
- Keep the recognizer smaller and more inspectable than a complete AWK parser.
- Exercise difficult newline contexts across the repository's portability matrix.

## Decision

AWK Minifier SHALL classify physical newlines as part of lexical/contextual
transformation.

For successful portable-AWK input, transformed output SHALL contain no physical
newlines except the newline immediately following a preserved first-line shebang.
Consequently:

- input with a preserved first-line shebang SHALL produce exactly one physical
  newline;
- input without a shebang SHALL produce zero physical newlines; and
- a trailing physical newline SHALL NOT be added merely to make the output a
  conventional text file.

This physical-line invariant describes transformed program source.  It does not
require build-owned release metadata to be passed through the current candidate
transformer; ADR-022 continues to govern production `.min.awk` construction.

### Newline classes

The transformer SHALL handle source newlines according to these classes:

1. **Shebang boundary.**  The newline terminating a first-line `#!` shebang SHALL
   be preserved so the following program does not become part of the interpreter
   directive.
2. **Explicit continuation.**  A backslash immediately followed by newline outside
   a comment SHALL be removed as a pair.  It SHALL NOT create a statement
   terminator or reset expression context.
3. **Blank or comment-only line.**  A newline on a physical source line containing
   no significant token SHALL be discarded.
4. **Grammar-optional newline.**  A newline accepted through a grammar
   `newline_opt` position SHALL be discarded.  A single ASCII space MAY be emitted
   when removing the newline is necessary to keep adjacent keyword/token text
   lexically separate, notably after `do` or `else`.
5. **Statement or rule terminator.**  Any remaining significant newline SHALL be
   represented by `;` rather than by a physical newline.

Leading horizontal indentation on a new physical source line SHALL remain
removable indentation.  Collapsing the entire program onto one output line MUST
NOT accidentally turn source indentation into new separator spaces after every
inserted semicolon.

### Context required for optional newlines

The recognizer SHALL maintain enough explicit context to distinguish at least:

- ordinary and control-statement parentheses;
- the closing parenthesis of `if`, `for`, and ordinary `while` headers;
- function-definition headers before their opening action brace;
- top-level rule actions, top-level function actions, and nested actions;
- `do` statements and the brace depth at which their body begins; and
- an ordinary `while` statement from the trailing `while` belonging to a pending
  `do` statement.

A nested action closing brace is already a terminated statement and therefore does
not require an inserted semicolon before a following statement, `else`, or
`do ... while` trailer.  A top-level rule still requires item separation; a
function definition may use its grammar-defined optional newline after the closing
brace.

The transformer SHALL continue to use contextual slash recognition and buffered
publication from ADR-018.  Newline handling MUST NOT replace those mechanisms with
raw regular-expression substitutions over source lines.

### Candidate self-minification

Candidate self-minification remains test-only under ADR-019 and ADR-022.  Tests MAY
run the current modular transformer over the current development artifact to prove
that the maintained source collapses to the shebang plus a single program line.
That evidence MUST NOT replace the pinned previous-release transformer used for
production `.min.awk` provenance.

## Promises

1. Successful transformed source contains at most one physical newline, and that
   newline exists only after a preserved first-line shebang.
2. Newlines that terminate statements or rules become semicolons rather than
   disappearing.
3. Grammar-optional newlines disappear without creating empty control bodies.
4. Explicit backslash-newline continuation is removed without becoming a
   statement boundary.
5. Ordinary `while` headers and `do ... while` trailers are distinguished.
6. The transformation remains portable AWK and is tested under multiple AWK
   implementations.
7. Semantic preservation remains more important than reducing another byte.

## Non-Promises

1. Newline elimination does not make the transformer a complete AWK parser or
   syntax validator.
2. The output is not promised to be the smallest possible byte representation;
   safe horizontal separator spaces may remain.
3. Implementation-specific AWK extensions are not automatically part of the
   portable input contract merely because one tested interpreter accepts them.
4. The current candidate is not promoted to its own production build trust root.
5. A missing trailing newline in transformed output is intentional and is not a
   promise that every downstream text-processing tool treats the file identically
   to a newline-terminated text file.

## Considered Alternatives

### Continue Preserving Physical Newlines

Rejected.  The first implementation established semantic safety, but preserving
all line boundaries leaves a large and unnecessary portion of source formatting in
a product whose purpose is minification.

### Delete Every Newline

Rejected because NEWLINE is a real AWK grammar token.  Deleting a statement or
rule terminator can merge constructs or change control flow.

### Replace Every Newline with a Semicolon

Rejected because grammar-optional newlines after control headers, `do`, `else`,
commas, and other continuation contexts are not statement terminators.  Inserting
a semicolon after `if (condition)` or an ordinary `while (condition)`, for example,
can create an empty body and change the program while remaining syntactically
plausible.

### Preserve Newlines Around All Control Flow

Rejected as unnecessarily conservative.  The POSIX grammar identifies where
newlines are optional, and small explicit context stacks can distinguish the
important cases without retaining hundreds of line breaks.

### Implement a Complete AWK Parser First

Rejected for the current scope.  A full parser could classify every grammatical
boundary, but it would substantially expand the implementation and audit surface.
The selected recognizer records only the structural context necessary for the
newline decision while retaining conservative behavior elsewhere.

### Use the Current Candidate to Build Its Own `.min.awk`

Rejected by ADR-019 and ADR-022.  Candidate self-minification is useful behavioral
evidence, not production release provenance.

## Consequences

The lexer gains explicit parenthesis, brace, function-header, and `do ... while`
state.  The output layer preserves a physical newline only for a shebang boundary;
ordinary source-line boundaries become either nothing or semicolons.

Tests must cover exact physical-line counts, statement separation, top-level rule
separation, control headers on the preceding line, nested conditionals, ordinary
`while`, `for`, simple and braced `do ... while`, function-definition line breaks,
explicit backslash continuation, comments around optional newlines, semantic
equivalence, idempotence, and candidate self-minification.

This change deliberately improves the runtime transformer before the production
build transformer is advanced.  A release containing this behavior can therefore
become a future previous-release trust anchor without weakening ADR-022's build
lineage.

## Superseded Decisions

This ADR refines ADR-018's conservative whitespace/newline treatment.  ADR-018's
portable-AWK runtime, contextual recognition, semantic-preservation priority, and
buffered-output requirements remain governing.

This ADR does not supersede ADR-019 or ADR-022.  Those decisions continue to govern
how a released `.min.awk` artifact is produced and which released transformer may
participate in that production path.

## Related Decisions

- ADR-008: Documentation-Driven, Test-Second Development
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-018: Portable AWK Runtime and Explicit Source Assembly
- ADR-019: Release Artifacts and Bootstrap Minification
- ADR-021: AWK Documentation and Portability Testing
- ADR-022: Pin v0.1.0 as the Production Minification Transformer
