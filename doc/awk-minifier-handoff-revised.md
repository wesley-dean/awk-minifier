# AWK Minifier Implementation Handoff

## Purpose

This document is the implementation handoff for the `awk-minifier` project:

https://github.com/wesley-dean/awk-minifier

It is intended to be attached to, uploaded to, or referenced by a GitHub issue so that a new ChatGPT process can be given the issue URL and a short instruction such as:

> Please implement this.

The implementation process should be able to use this document as the historical, architectural, procedural, and testing context for the work.  It is intentionally detailed.  When this handoff and current repository governance differ, the repository's current Accepted ADRs and imported standards govern unless they are deliberately superseded through the project's normal ADR process.

The process must not begin by writing code.

It must begin by reading the repository, its governance, this handoff, the current reusable coding standards, the relevant model repositories, and the AWK language references.  It must then produce a detailed implementation plan, identify any conflicts with inherited governance, state material assumptions, propose the required ADR changes, and only then implement.

Depth and correctness are more important than speed.

---

# 1. Executive directive

Build a conservative, portable AWK source minifier whose primary contract is:

```text
AWK source on STDIN
        |
        v
    awk-minifier
        |
        v
minified AWK source on STDOUT
```

The final product itself should be written in portable AWK.

Bash and Make remain repository-development and orchestration tools.  `bashdeps` is the dependency and reusable-governance materializer.  The product itself should not require Bash at runtime.

The minifier should:

1. read AWK source only from standard input;
2. write successfully minified AWK source only to standard output;
3. write diagnostics only to standard error;
4. exit zero only when transformation succeeds;
5. preserve the semantics of supported input;
6. prefer conservative output over maximum byte reduction;
7. preserve or reject constructs that cannot be transformed safely;
8. target portable POSIX AWK as the primary language compatibility baseline;
9. avoid GNU-awk-only behavior in product code unless an explicit later decision changes the portability floor;
10. be maintained as responsibility-focused modular AWK source;
11. be runnable in modular form through repeated `awk -f` arguments;
12. be assembled deterministically with `cat` in a Make-driven build;
13. produce three single-file distribution artifacts;
14. produce one `.sha256` companion for each artifact;
15. use a previously reviewed, Bashdeps-pinned AWK Minifier release to build the minified distribution artifact;
16. never use the candidate-under-development as the trusted build minifier;
17. retain self-minification as a test only;
18. use unusually exhaustive unit, regression, semantic-equivalence, portability, and adversarial testing;
19. import project governance and examples from `wesley-dean/coding_standards` through Bashdeps exactly as described later in this handoff; and
20. preserve the repository's explicit network, dependency, build, release, and documentation boundaries.

The standard for success is not:

> The tool usually removes a lot of whitespace.

The standard is:

> For the AWK language boundary the project explicitly claims to support, there is unusually strong evidence that the output remains the same AWK program.

---

# 2. Repository starting point

The target repository already exists:

```text
wesley-dean/awk-minifier
```

It is not an empty repository.

At the time this handoff was revised, the repository was seeded from `template-bash`.  It already contained:

- `README.md`;
- `AGENTS.md`;
- a substantial Accepted ADR corpus;
- `doc/decisions.md`;
- `doc/engineering-philosophy.md`;
- `doc/testing.md`;
- `doc/release-verification.md`;
- `doc/threat-modeling.md`;
- a Bash-oriented `doc/documentation-standard.md`;
- a Makefile;
- Bashdeps integration;
- Bash-Minifier as a dependency;
- Bash Doxygen tooling;
- Bats tests;
- CI and release workflows;
- the standard template repository-support files;
- a generated-artifact model with development, ordinary, and minified Bash flavors.

The repository therefore has useful architecture and governance that should be adapted rather than discarded.

The implementation process must follow the repository startup workflow before changing anything:

1. read `README.md`;
2. read `AGENTS.md`;
3. read `doc/engineering-philosophy.md`;
4. read `doc/testing.md`;
5. read `doc/release-verification.md`;
6. read `doc/threat-modeling.md`;
7. read `doc/decisions.md`;
8. read every ADR under `doc/adr/`;
9. inspect `Makefile`;
10. inspect all dependency manifests;
11. inspect all CI and release workflows;
12. inspect the current source and tests;
13. inspect all existing repository-facing documentation;
14. identify inherited template material that is still authoritative, material that needs refinement, and material that must be superseded.

Do not simply delete the starter ADRs because the product is no longer a Bash program.

Several decisions remain directly useful.

Others are now in conflict with the intended AWK product and must be deliberately superseded or materially revised.

---

# 3. Important current governance that should be preserved where applicable

The existing template-derived repository already contains useful Accepted decisions around:

- capability scope and epistemic honesty;
- documentation and decision hierarchy;
- Make as the canonical orchestration interface;
- modular maintained source;
- explicit dependency/network boundaries;
- three generated artifact flavors;
- documentation-driven, test-second development;
- behavior testing across shipped artifacts;
- ephemeral generated reference documentation;
- Conventional Commit-driven semantic releases;
- late tagging after validation;
- `.sha256` checksum companion naming;
- repository-facing documentation hygiene;
- modularity as maintenance and assembly architecture;
- dependencies as explicit attack surface;
- threat modeling; and
- ephemeral ADR navigation.

The implementation process should reuse those decisions when their intent remains correct.

It should not preserve Bash-specific mechanics merely because they are currently Accepted.

---

# 4. Existing decisions that need explicit review, refinement, or supersession

The current ADR corpus was inherited from `template-bash`.

At minimum, the implementation process must review the following areas for conflict with the new AWK architecture.

## 4.1 Bash runtime and portability baseline

The current repository contains a Bash runtime baseline decision.

The product is now intended to be AWK.

That decision cannot remain the product runtime decision unchanged.

A new or superseding ADR should establish:

- POSIX AWK as the default product language contract;
- the intended supported AWK implementations;
- whether any non-POSIX extensions are recognized or preserved;
- what portability means for generated output;
- what portability means for the minifier implementation itself;
- which Bash requirements remain only for repository tooling;
- which Make implementation is expected;
- what CI evidence supports the portability claim.

Bash may remain the Make recipe shell and shell-test-harness language.

That is not the same thing as requiring Bash at product runtime.

## 4.2 Modular source and plugin discovery

The starter includes a plugin registry and automatic plugin discovery.

The AWK Minifier should preserve the general modularity lesson:

- responsibility-focused modules;
- deterministic assembly;
- explicit source order where order matters;
- standalone generated artifacts.

It should not preserve the example runtime plugin architecture unless a genuine product requirement appears.

The minifier does not currently need dynamic plugins.

The implementation process should likely supersede or refine the plugin-discovery decision to establish explicit AWK source ordering.

## 4.3 Release artifact flavor decision

The existing three-flavor artifact concept is highly relevant.

The Bash filenames and executable metadata mechanics are not.

The AWK-specific artifact contract should become:

```text
dist/awk-minifier.dev.awk
dist/awk-minifier.dev.awk.sha256

dist/awk-minifier.awk
dist/awk-minifier.awk.sha256

dist/awk-minifier.min.awk
dist/awk-minifier.min.awk.sha256
```

All three AWK artifacts should implement the same STDIN-to-STDOUT public behavior contract.

## 4.4 Bash Doxygen documentation decision

The current local documentation standard is Bash-oriented.

The maintained product implementation will be AWK.

The project should adopt the reusable AWK Documentation Standard from `coding_standards` as described later in this document.

Any maintained Bash used only for repository helpers should follow the applicable imported Bash tooling guidance and any separately applicable Bash documentation rules if such maintained Bash exists.

The implementation must not silently continue applying a Bash source-documentation ADR to AWK source.

## 4.5 Bats-specific testing decision

The important invariant is behavior-oriented testing across all shipped artifacts.

Bats itself is an implementation choice inherited from a Bash starter.

A shell-based harness similar to `awk-doxygen/tests/run-tests.sh` may be a better fit for AWK fixtures.

The implementing process should evaluate this explicitly rather than keeping Bats solely through inertia.

Whatever harness is chosen, the artifact and semantic-equivalence requirements in this handoff are more important than the framework.

---

# 5. Current repository release caveat

At the time this document was revised, the repository already had a `v0.0.1` release.

That release is a template artifact, not a real AWK Minifier release.

Its assets are inherited `template-bash.*.bash` files.

Therefore:

```text
v0.0.1 != usable AWK Minifier bootstrap release
```

The implementation must not use that release as `vendor/awk-minifier.awk`.

The first actual AWK Minifier release has a bootstrap problem that must be solved deliberately and documented through an ADR.

That bootstrap issue is discussed in detail later.

---

# 6. Origin and history of the idea

The project grew from experience with:

```text
Zuzzuc/Bash-minifier
```

Repository:

https://github.com/Zuzzuc/Bash-minifier

Bash-Minifier attempts to transform Bash programs into compact source, often collapsing a script to one physical executable line after its shebang while preserving syntax that cannot safely be flattened.

Wesley Dean began using Bash-Minifier in his Bash build pipelines, including the three-artifact model used by projects such as Bootstrap and the `template-bash` starter.

The artifact model is:

```text
fully documented development artifact
            |
            v
ordinary comment-stripped artifact
            |
            v
minified artifact
```

This works well with Wesley's documentation-heavy development model:

- maintained source remains readable;
- Doxygen commentary remains rich;
- architecture and behavior are documented near code;
- ordinary distribution can remove maintenance prose;
- minified distribution can optimize for compact consumption;
- the same observable behavior suite can validate every representation.

The natural follow-up question became:

> Can the same concept be implemented for AWK programs?

The answer is yes, but AWK must be treated as its own language.

The new project should inherit engineering lessons from Bash-Minifier without mechanically porting Bash parser assumptions.

---

# 7. Relevant Bash-Minifier history and lessons

The implementing process should independently inspect current Bash-Minifier source, tests, issues, pull requests, and releases.

The following historical points are especially relevant.

## 7.1 Semicolon insertion became a correctness problem

Bash-Minifier encountered bugs around deciding where line boundaries required separators.

This matters because minification is not equivalent to removing indentation.

A newline can be syntax.

A separator can change parsing.

Adding or deleting a semicolon can change behavior.

AWK has the same class of problem.

The AWK implementation must define newline and separator transformations grammatically.

## 7.2 Comments are lexical structures

Bash-Minifier has had to distinguish real comments from `#` characters that occur inside quoted or otherwise syntactically meaningful content.

The AWK minifier must do the same.

For AWK, `#` inside:

- a string;
- a regular expression;
- a bracket expression inside a regular expression

must not be mistaken for a source comment.

Comment stripping must therefore be driven by lexer state.

## 7.3 Bash heredocs demonstrated the need for exceptional states

AWK does not have Bash heredocs.

The lesson still applies.

Some syntax cannot safely pass through a generic line-trimming transformation.

A source transformer needs explicit language states for constructs with different lexical rules.

For AWK, those include at least:

- strings;
- regular-expression literals;
- comments;
- regexp bracket expressions;
- escape handling;
- explicit line continuations;
- contexts that distinguish regexp literals from division.

## 7.4 Trailing backslash handling produced a concrete regression

Wesley reported a Bash-Minifier regression involving lines ending in multiple backslashes.

A simplistic:

```text
line ends with "\" => continuation
```

rule was incorrect.

The fix needed to consider how many backslashes occurred and whether the final backslash was itself escaped.

This is an important general testing lesson.

For every lexical boundary, test neighboring cases:

```text
one
two
three
four
```

rather than testing only the canonical example.

For AWK, the same philosophy should be used around:

- slash;
- backslash;
- quote;
- hash;
- newline;
- semicolon;
- braces;
- parentheses;
- bracket expressions;
- adjacent operators.

## 7.5 STDIN/STDOUT support was added later

Wesley previously requested pipeline-oriented STDIN/STDOUT support from Bash-Minifier.

For AWK Minifier, streaming is now the entire public data interface from the beginning.

There is no file-input or output-file option in the baseline design.

## 7.6 Textual golden tests are useful but not enough

Bash-Minifier primarily tests generated source against expected output.

That is valuable.

AWK Minifier must go farther because it is transforming executable code.

The AWK project should maintain both:

1. exact generated-source regression fixtures; and
2. semantic original-versus-minified execution tests.

A minifier has not been proven correct merely because its output matched the output that the test author expected.

---

# 8. Major architectural decision: implement the product in AWK

The initial idea considered implementing the minifier in Bash.

That is no longer the preferred architecture.

The product should be implemented in portable AWK.

Why:

- the problem is fundamentally lexical and textual;
- AWK is designed for text scanning;
- character and token scanning are more natural in AWK than Bash substring loops;
- state machines are easier to inspect in AWK;
- AWK avoids a large amount of shell quoting complexity;
- the minifier can dogfood the language it processes;
- the implementation itself can be tested across multiple AWK interpreters;
- performance should be materially better than Bash character-by-character scanning;
- the runtime surface becomes smaller;
- the final artifact can be a native single AWK file.

Bash remains useful for:

- Make recipes;
- dependency bootstrap logic;
- checksum generation;
- test harnesses;
- release workflows;
- repository tooling.

The runtime product should not require Bash.

---

# 9. Rejected alternative: implement the lexer/minifier entirely in Bash

This was the earliest design direction.

It was rejected because the hardest part of the project is language-aware text scanning.

Bash can do it, but the implementation would likely involve:

- expensive substring operations;
- more complicated state management;
- more quoting hazards;
- more shell-specific implementation complexity;
- a larger implementation surface unrelated to the AWK grammar.

Bash remains an excellent orchestration language in this ecosystem.

It is not the best language for the core lexer when AWK itself is available.

---

# 10. Considered then rejected alternative: Bash wrapper around an AWK engine

A second architecture was considered:

```text
Bash CLI
   |
   v
embedded or external AWK engine
```

This would have allowed Bash to manage:

- file arguments;
- output paths;
- overwrite protection;
- temporary files;
- permissions;
- rich CLI option handling.

The idea became unnecessary once the public interface was intentionally reduced to:

```text
STDIN -> STDOUT
```

The wrapper would add runtime complexity without serving a meaningful product requirement.

The minifier therefore should not have a Bash runtime wrapper merely for familiarity.

---

# 11. Decided public interface: STDIN only and STDOUT only

The product interface should remain deliberately narrow.

Normal operation:

```bash
awk -f awk-minifier.awk < input.awk > output.awk
```

Pipeline operation:

```bash
producer | awk -f awk-minifier.awk | consumer
```

Public channels:

```text
STDIN   AWK source input
STDOUT  successfully transformed AWK source
STDERR  diagnostics only
status  success/failure
```

The baseline should not provide:

```text
-f / --file
-o / --output
--force
filesystem overwrite handling
temporary output management
output permissions
```

Those responsibilities belong to the caller.

This gives the project a very strong UNIX-composition boundary.

---

# 12. Rejected alternative: rich file-oriented CLI

A Bash-Minifier-like file CLI was considered.

It was rejected for the baseline because:

- it expands the public API;
- it introduces filesystem semantics unrelated to minification;
- it introduces overwrite policy;
- it introduces atomic-replacement policy;
- it introduces path security concerns;
- it creates a reason for a Bash wrapper;
- every needed file use case is already expressible with shell redirection.

If a future use case genuinely requires a file API, that should be a later deliberate interface decision.

---

# 13. Modular maintained AWK source

The source should be modular.

The project should not maintain one giant AWK implementation solely because the released product is one file.

Responsibility-focused modules are preferred.

A possible shape is:

```text
src/
├── constants.awk
├── diagnostics.awk
├── token-types.awk
├── lexer.awk
├── regexp.awk
├── separators.awk
├── minifier.awk
└── main.awk
```

This is illustrative, not mandatory.

The implementation process must derive module boundaries from responsibilities and the imported Clean Architecture / Clean Coding governance.

Do not split code merely to increase file count.

Do not force every file to be independently useful.

---

# 14. Modular execution during development

One attractive AWK property is that modular source can be executed directly:

```bash
awk \
  -f src/constants.awk \
  -f src/diagnostics.awk \
  -f src/token-types.awk \
  -f src/lexer.awk \
  -f src/regexp.awk \
  -f src/separators.awk \
  -f src/minifier.awk \
  -f src/main.awk
```

Therefore:

- individual modules should be valid AWK source;
- individual modules do not need independent standalone behavior;
- the complete module set should be an executable development representation;
- tests should be able to exercise the modular source set directly.

This gives the project an important diagnostic surface:

```text
modular source
```

in addition to the generated artifacts.

If a generated artifact fails while modular source passes, the build transformation becomes the prime suspect.

---

# 15. Rejected alternative: maintain a single AWK source file

Maintaining a single source file would simplify the build.

It was rejected as the primary development architecture because the project is expected to contain nontrivial lexical and grammar-aware logic.

Modular maintained source provides:

- clearer ownership boundaries;
- easier review;
- easier testing;
- less accidental coupling;
- smaller changes;
- alignment with Wesley's existing Bash project practices.

The release artifact remains single-file, so consumers do not pay for development modularity.

---

# 16. Deterministic source ordering

The Makefile should declare semantically meaningful source order explicitly.

Avoid:

```text
find ... | sort
```

as the primary mechanism for core implementation order.

A likely Make shape:

```make
SOURCE_FILES := \
    src/constants.awk \
    src/diagnostics.awk \
    src/token-types.awk \
    src/lexer.awk \
    src/regexp.awk \
    src/separators.awk \
    src/minifier.awk \
    src/main.awk
```

The exact list is an implementation-plan decision.

If an additive class of source is ever intentionally discovered, that should be separately governed.

Do not preserve the template's plugin discovery merely because it exists today.

---

# 17. Build artifact contract

The project should publish one family of AWK artifacts:

```text
dist/awk-minifier.dev.awk
dist/awk-minifier.dev.awk.sha256

dist/awk-minifier.awk
dist/awk-minifier.awk.sha256

dist/awk-minifier.min.awk
dist/awk-minifier.min.awk.sha256
```

No `.256` companions should be generated for new builds.

If historical `.256` compatibility remains governed by inherited ADRs, retain only the compatibility behavior that still matters.

All three AWK files are generated products.

None should be hand-edited.

---

# 18. Development artifact

`awk-minifier.dev.awk` should contain:

- an AWK shebang if the project chooses executable artifacts;
- build provenance as comments;
- the complete maintained AWK implementation;
- all Doxygen/source comments;
- deterministic module assembly;
- no source-comment stripping;
- no minification.

The intended lineage is:

```text
maintained modules
     |
     | explicit ordered cat
     v
awk-minifier.dev.awk
```

The implementation process should carefully handle module boundaries.

A missing final newline in one source module must never merge tokens with the next module.

Options include:

- require and verify exactly one final newline in each module; and/or
- deliberately emit a newline between concatenated modules.

This should be tested.

---

# 19. Ordinary artifact

`awk-minifier.awk` should be derived from the complete assembled development artifact.

Its transformation should be deliberately conservative.

The preferred conceptual model is:

```text
awk-minifier.dev.awk
       |
       | remove full-line comments
       | preserve shebang
       v
awk-minifier.awk
```

The ordinary-artifact stripping phase should not become a second AWK parser.

It should not attempt aggressive inline-comment removal.

It should not minify.

Its purpose is to provide the readable middle representation between fully documented source and aggressive minification.

---

# 20. Minified artifact

`awk-minifier.min.awk` should be derived from the ordinary artifact.

It must be produced using a Bashdeps-pinned, previously reviewed AWK Minifier artifact under `vendor/`.

Conceptually:

```text
dist/awk-minifier.awk
        |
        | awk -f vendor/awk-minifier.awk
        v
dist/awk-minifier.min.awk
```

The minified artifact must not be produced using the current candidate source.

This is a deliberate trust boundary.

---

# 21. Critical decision: pinned released minifier is the build transformer

The current candidate must not minify itself as part of the production build.

Instead, Bashdeps should materialize an immutable, reviewed AWK Minifier artifact:

```text
vendor/awk-minifier.awk
```

with:

- an immutable release URL;
- a committed SHA-256 digest;
- an explicit dependency identity.

A future manifest entry may resemble:

```text
id=wesley-dean/awk-minifier@<version> \
url=https://github.com/wesley-dean/awk-minifier/releases/download/v<version>/awk-minifier.awk \
dest=vendor/awk-minifier.awk \
digest=sha256:<digest>
```

Use the actual current Bashdeps manifest grammar.

The pinned version is not required to be the immediately previous version.

The rule is:

> Use a specifically reviewed known-good released minifier.

The build dependency should change only through an explicit dependency update.

---

# 22. Why the pinned build transformer is better than build-time self-minification

Using a pinned released minifier:

- prevents current bugs from silently participating in their own release transformation;
- makes build-tool bytes explicit;
- makes transformer upgrades reviewable;
- gives the minified artifact a stable provenance relationship;
- aligns with existing Bashdeps trust boundaries;
- mirrors the stable released-self-consumption model already used in `awk-doxygen`;
- separates "candidate under test" from "trusted build tool";
- prevents accidental circular confidence.

This is stronger than using the candidate to create its own release artifact.

---

# 23. `awk-doxygen` precedent

The `wesley-dean/awk-doxygen` project provides an important precedent.

It intentionally uses a Bashdeps-pinned released `awk-doxygen` artifact for stable documentation generation while current repository source remains independently tested as a canary.

The conceptual distinction is:

```text
released pinned tool
    trusted stable consumer path

current source
    candidate under development and test
```

AWK Minifier should adopt the same mental model:

```text
vendor/awk-minifier.awk
    trusted build transformer

current modular source / dist/awk-minifier.awk
    candidate under test
```

Do not conflate the two roles.

---

# 24. Self-minification must remain a test only

The current candidate should still minify itself as a test.

That is valuable dogfooding.

Example:

```bash
awk -f dist/awk-minifier.awk \
    < dist/awk-minifier.awk \
    > temporary-self-minified.awk
```

The temporary result should then be subjected to appropriate validation and semantic tests.

However:

```text
temporary-self-minified.awk
```

is not the production build source for:

```text
dist/awk-minifier.min.awk
```

The production minified artifact comes from the pinned vendored release.

---

# 25. Candidate self-minification need not equal pinned-build output byte-for-byte

Suppose:

```text
candidate source = version 0.0.8 development
pinned build tool = version 0.0.6
```

Version 0.0.8 may intentionally produce different minified formatting from 0.0.6.

Therefore:

```text
pinned-release minification
```

and:

```text
candidate self-minification
```

must both preserve behavior, but they are not automatically required to produce identical bytes.

Do not write a test that falsely couples candidate output to an older transformer unless byte compatibility is intentionally part of the contract.

---

# 26. Idempotence

Idempotence is a strong candidate contract:

```text
minify(minify(source)) == minify(source)
```

The implementation process should evaluate and likely govern byte-for-byte idempotence through an ADR.

If adopted:

- test it on ordinary fixtures;
- test it on real-world corpora;
- test it on `awk-minifier.awk`;
- test it under each supported AWK interpreter.

If exact idempotence is intentionally not guaranteed, document why.

---

# 27. First-real-release bootstrap problem

The project wants to build the minified artifact using a previously released AWK Minifier.

The repository currently has no usable AWK Minifier release.

The existing `v0.0.1` contains template Bash artifacts and cannot be used.

Therefore the first actual AWK Minifier release requires an explicit bootstrap strategy.

This is not a detail to hide in Make.

It should receive an ADR.

Possible approaches include:

## Option A: first real release ships only development and ordinary artifacts

Then that release becomes the trusted minifier used to create the `.min.awk` flavor in subsequent releases.

Advantages:

- no self-trust bootstrap;
- conceptually clean.

Disadvantages:

- first real release does not satisfy the intended three-artifact contract.

## Option B: create a separately reviewed seed artifact

A first AWK implementation is produced, tested unusually thoroughly, frozen at an immutable commit or dedicated bootstrap artifact, SHA-256 pinned, and used as the build transformer for the first full three-flavor AWK release.

Advantages:

- first real release can have the final artifact shape;
- bootstrap trust is explicit;
- the candidate does not directly transform itself.

Disadvantages:

- introduces a one-time seed process;
- seed provenance must be documented carefully.

## Option C: one-time self-hosted bootstrap

The first real AWK release uses its current ordinary artifact to produce its minified artifact.

After that release, all future builds pin a released minifier.

Advantages:

- operationally straightforward.

Disadvantages:

- weakens the desired build trust boundary for the most important bootstrap release;
- requires a one-time exception.

The earlier discussion leaned toward a separately reviewed seed approach if it can be made clean.

This handoff does not silently finalize that choice.

The implementation process must propose a concrete bootstrap plan, explain its trust model, and record the decision before the first real release.

---

# 28. Make and build boundaries

Make remains the canonical orchestration interface.

Preserve the existing repository principle that dependency acquisition and ordinary build are different operations.

Expected conceptual targets include:

```text
make deps
make deps-check

make standards
make standards-check

make build
make checksums

make check
make format

make test
make test-report

make adr-index
make docs

make clean
make distclean
```

The implementation process may refine names where governance requires, but the boundaries matter.

---

# 29. Network-boundary requirements

`make deps` may use the network.

It may:

- bootstrap Bashdeps;
- synchronize `vendor/awk-minifier.awk`;
- synchronize Doxygen filters;
- synchronize adrctl;
- synchronize other repository dependencies.

`make deps-check` must:

- use no network;
- perform no repair;
- verify already prepared state;
- fail when expected bytes are missing or wrong.

`make standards` may use the network.

`make standards-check` must be offline and non-repairing.

`make build` must:

- use no network;
- not invoke dependency synchronization;
- consume prepared pinned state;
- fail clearly if the pinned minifier required for `.min.awk` is absent.

`make docs` must remain offline after preparation.

`make all` may explicitly sequence networked preparation before an offline build.

Do not make `build -> deps` an implicit prerequisite.

---

# 30. Bashdeps bootstrap

Continue the existing pattern:

- Make directly owns only the bootstrap copy of `vendor/bashdeps.bash`;
- Bashdeps itself is pinned to an immutable release;
- the expected SHA-256 digest is committed;
- cached bytes are verified before execution;
- a replacement download is staged;
- the staged candidate is verified before publication;
- failed acquisition never destroys a previously valid cached copy.

Do not use Bashdeps to bootstrap its first copy.

Do not download ordinary dependencies directly from ad hoc Make recipes when they fit the Bashdeps model.

---

# 31. Coding standards are mandatory project governance

The implementation session must use:

https://github.com/wesley-dean/coding_standards

The current `coding_standards` README contains the authoritative consumption pattern.

The implementation session must read that README before creating the standards manifest.

Do not copy standards manually.

Do not use Git submodules.

Do not fetch moving `main` at ordinary build time.

Use Bashdeps.

Use an immutable reviewed source reference, such as a Git commit or immutable release.

Commit SHA-256 digests for every imported file.

---

# 32. Required `coding_standards` content

The user has explicitly selected the following standards content.

## Standards

```text
standards/
├── general/
│   ├── clean-architecture-standard.md
│   ├── clean-coding-standard.md
│   └── conventional-commit-release-governance.md
├── awk/
│   └── documentation-standard.md
├── bash/
│   └── tooling-standard.md
├── markdown/
│   └── markdown-standard.md
├── repository/
│   ├── repository-standard.md
│   └── github-standard.md
└── adr/
    └── adr-standard.md
```

## Examples

```text
examples/
├── general/
│   └── clean-coding/
├── awk/
│   └── documentation/
│       └── example.awk
├── markdown/
├── repository/
└── adr/
```

The implementation process should inspect those directories at execution time and import the actual files present under them.

When an example directory contains multiple files, import the applicable files recursively and preserve relative paths.

Git does not preserve empty directories, so only actual files need Bashdeps declarations.

---

# 33. Required local standards layout

The mapping is explicit.

Everything under upstream:

```text
standards/
```

goes under:

```text
doc/standards/
```

with its relative path preserved.

Everything under upstream:

```text
examples/
```

goes under:

```text
doc/standards/examples/
```

with its relative path preserved.

Therefore examples include:

```text
standards/general/clean-coding-standard.md
    ->
doc/standards/general/clean-coding-standard.md
```

```text
standards/awk/documentation-standard.md
    ->
doc/standards/awk/documentation-standard.md
```

```text
standards/bash/tooling-standard.md
    ->
doc/standards/bash/tooling-standard.md
```

```text
standards/repository/github-standard.md
    ->
doc/standards/repository/github-standard.md
```

```text
examples/awk/documentation/example.awk
    ->
doc/standards/examples/awk/documentation/example.awk
```

Do not flatten the imported paths.

Do not place examples beside normative standards without the `examples/` boundary.

---

# 34. Standards manifest

Create a dedicated standards manifest, likely:

```text
dependencies-standards.txt
```

unless current repository governance establishes another name.

Each imported file should have:

- a stable identity;
- an immutable source URL;
- the chosen immutable upstream ref;
- a destination under `doc/standards/`;
- a committed SHA-256 digest.

The destination root must be constrained.

Follow the `coding_standards` README pattern:

```bash
vendor/bashdeps.bash sync \
    --dest-root doc/standards \
    dependencies-standards.txt
```

Offline verification:

```bash
vendor/bashdeps.bash verify \
    --dest-root doc/standards \
    dependencies-standards.txt
```

The exact Bashdeps syntax must be confirmed from the pinned Bashdeps release.

---

# 35. Standards Make targets

Add explicit targets modeled on the `coding_standards` README:

```text
make standards
make standards-check
```

`make standards`:

- may use the network;
- bootstraps/verifies Bashdeps as needed;
- synchronizes the standards manifest;
- writes only below `doc/standards/`.

`make standards-check`:

- does not use the network;
- does not repair;
- verifies Bashdeps;
- verifies every synchronized standard/example byte.

The regular product build should not silently update standards.

---

# 36. Imported standards are not locally editable

Files under:

```text
doc/standards/
```

are synchronized snapshots.

They should not be edited locally to accommodate the project.

If the project needs an exception:

- document it locally;
- use an ADR when consequential;
- keep the upstream standard unchanged;
- change the upstream canonical standard separately if the standard itself should evolve.

The project's `AGENTS.md` should explicitly say this.

---

# 37. Normative standards versus examples

The imported `standards/` content is normative.

The imported `examples/` content is illustrative.

If a synchronized example conflicts with a synchronized standard:

```text
the standard wins
```

and the upstream example should eventually be corrected.

Do not allow a convenient example to silently redefine governance.

---

# 38. Language problem: AWK is not a whitespace-insensitive format

The minifier should be treated as a language tool.

It should not be designed as:

```text
sed + tr + hope
```

Important AWK syntax issues include:

- `/` can mean regexp delimiter or division;
- newlines can be grammar tokens;
- whitespace can separate tokens;
- whitespace can participate in implicit concatenation;
- function-call spacing has syntactic meaning;
- comments end at newline;
- explicit backslash-newline continuation has language meaning;
- regular-expression bracket expressions have their own scanning rules;
- redirection syntax appears in expression-like contexts;
- adjacent operators can change tokenization.

The implementation must understand enough lexical and grammar context to make safe transformations.

---

# 39. Primary lexical challenge: regexp literal versus division

These uses of `/` are different:

```awk
/foo/ { print }
```

```awk
$0 ~ /foo/ { print }
```

```awk
$0 !~ /foo/ { print }
```

```awk
x = a / b
```

```awk
x /= 2
```

A rule such as:

```text
outside a string, slash begins a regexp
```

is wrong.

A rule such as:

```text
if another slash exists later, this is a regexp
```

is also wrong.

The implementation must use enough token/grammar context to determine whether a regexp literal may begin at the current position.

This deserves its own ADR or a prominent section in the parser/lexer ADR.

---

# 40. Do not make parser-level work taboo

The project may not need a complete AWK AST parser.

It almost certainly needs more than regular-expression substitutions.

Think of the architecture continuum:

```text
regex replacement
    -> too weak

character state machine
    -> necessary but perhaps insufficient

tokenizer + contextual lexer
    -> likely baseline

partial grammar recognizer
    -> potentially necessary

full parser / AST
    -> possibly unnecessary, but should not be rejected dogmatically
```

Choose the smallest architecture that can explain and defend each transformation.

Correctness, inspectability, and failure behavior matter more than code-size aesthetics.

---

# 41. Candidate lexer state model

A starting conceptual state model may include:

```text
NORMAL
STRING
REGEXP
COMMENT
```

plus context for:

- escapes;
- bracket expressions inside regexps;
- previous significant token;
- current token class;
- whether an operand or operator is expected;
- whether regexp syntax may begin;
- parenthesis depth;
- bracket depth;
- brace depth;
- explicit continuation;
- physical line boundary;
- logical statement boundary.

This is not a final parser specification.

The implementation plan must derive actual states from the AWK grammar.

---

# 42. Newlines are grammar

Do not:

```text
replace every newline with semicolon
```

Do not:

```text
delete every newline
```

The implementation must distinguish:

- newline as statement terminator;
- newline as optional whitespace;
- newline permitted after continuation-capable syntax;
- explicit backslash-newline;
- newline terminating a source comment;
- newline that must become one space to preserve token separation;
- newline that must become `;`;
- newline that may disappear entirely;
- newline that must remain.

Study the current POSIX AWK grammar directly.

---

# 43. Comments

POSIX AWK comments begin with `#` and terminate at newline.

Comment recognition must respect lexer state.

Required cases include:

```awk
# comment
BEGIN { print "hello" }
```

```awk
BEGIN { print "foo # bar" }
```

```awk
/#/ { print }
```

```awk
/[#]/ { print }
```

```awk
BEGIN { x = 1 } # comment
```

When a comment separates two lexical tokens, removing it may require emitting replacement whitespace or a separator.

Do not simply delete bytes from `#` through newline and concatenate the surrounding text.

---

# 44. Strings

Test strings involving:

- empty string;
- spaces;
- `#`;
- `/`;
- `\`;
- escaped quote;
- escaped backslash;
- braces;
- parentheses;
- brackets;
- semicolons;
- commas;
- operator-looking text;
- comment-looking text;
- regexp-looking text;
- strings near implicit concatenation;
- strings at EOF;
- malformed strings.

Do not normalize string escape spelling merely for compactness.

---

# 45. Regular expressions

The regexp fixture corpus should be extensive.

Include:

- pattern regexp;
- regexp after `~`;
- regexp after `!~`;
- escaped slash;
- slash inside bracket expression;
- hash inside regexp;
- hash inside bracket expression;
- POSIX character classes;
- anchors;
- grouping;
- alternation;
- intervals;
- literal spaces;
- repeated backslashes;
- regexp adjacent to action brace;
- malformed/unterminated regexp.

The first version should preserve regexp bytes rather than attempting to minify regexp internals.

---

# 46. Regexp bracket state

A regexp scanner likely needs a bracket-expression substate.

For example:

```awk
/[a-z/]/
```

cannot be scanned correctly if every unescaped slash automatically closes the regexp regardless of bracket context.

Study POSIX ERE rules carefully.

Do not assume PCRE or JavaScript regexp behavior.

---

# 47. Explicit backslash-newline continuation

Test aggressively.

Neighboring cases:

```text
one backslash
two backslashes
three backslashes
four backslashes
```

Test in:

- ordinary source;
- strings;
- regexps;
- near comments;
- near commas;
- near logical operators;
- near concatenation;
- near function calls.

Also test:

- LF;
- CRLF if supported;
- backslash followed by spaces then newline;
- EOF after backslash.

The Bash-Minifier regression around trailing backslashes is the historical warning here.

---

# 48. AWK implicit concatenation

AWK concatenation through adjacency makes whitespace removal unusually sensitive.

The minifier must preserve the distinction between:

```awk
a b
```

and tokens that would merge if space disappeared.

Test:

- identifier + identifier;
- string + variable;
- variable + string;
- field + string;
- function result + string;
- parenthesized expression + expression;
- numeric-looking adjacency;
- concatenation around operators.

When uncertain, preserve one space.

---

# 49. Function-call spacing

POSIX AWK has syntactic constraints around function name followed by `(`.

The minifier must not invent or remove whitespace based solely on style.

Test:

- user-defined calls;
- built-ins;
- nested calls;
- function definitions;
- omitted formals used as locals;
- calls participating in concatenation;
- calls adjacent to operators.

---

# 50. Pattern/action boundaries

Test:

- `BEGIN`;
- `END`;
- regexp pattern + action;
- expression pattern + action;
- range pattern;
- pattern-only rule;
- action-only rule;
- empty action;
- multiple adjacent rules;
- functions interspersed with rules;
- nested action blocks.

The minifier must never accidentally attach an action to a different pattern or merge adjacent rules.

---

# 51. Operators

Build a systematic operator matrix.

Include:

- `=`;
- `+=`;
- `-=`;
- `*=`;
- `/=`;
- `%=`;
- arithmetic operators;
- comparison operators;
- `~`;
- `!~`;
- `&&`;
- `||`;
- `!`;
- `++`;
- `--`;
- ternary `? :`;
- membership `in`;
- field `$`;
- print redirection;
- append redirection;
- pipe;
- semicolon;
- comma;
- braces;
- brackets;
- parentheses.

Test whitespace deletion around every multi-character operator so shorter tokens cannot merge into a different operator.

---

# 52. Control flow

Test:

- `if`;
- `if/else`;
- nested conditionals;
- `while`;
- `do/while`;
- C-style `for`;
- `for (x in a)`;
- `break`;
- `continue`;
- `next`;
- `exit`;
- `return`;
- `delete`.

Test conventional formatting and unusual valid formatting.

Do not assume input was formatted by a particular tool.

---

# 53. I/O and side effects

Semantic fixtures should include:

- normal STDIN;
- multiple records;
- multiple files where harness invocation requires them;
- `getline`;
- `getline var`;
- command pipe to `getline`;
- `print`;
- `printf`;
- output redirection;
- append redirection;
- `print | command`;
- `close()`;
- `system()`;
- `exit` status;
- `ARGV`;
- `ARGC`;
- `ENVIRON`;
- `FILENAME`;
- `FNR`;
- `NR`;
- `FS`;
- `RS`;
- `OFS`;
- `ORS`;
- `SUBSEP`;
- `OFMT`;
- `CONVFMT`.

Use controlled temporary directories.

Never execute untrusted arbitrary user AWK as part of minification.

Tests execute trusted repository fixtures only.

---

# 54. Portability baseline

The intended baseline should be portable POSIX AWK.

The implementation process must confirm this in an ADR.

Avoid implementation-specific production features unless explicitly governed.

At minimum, investigate CI coverage for:

```text
gawk
mawk
BusyBox awk
One True Awk / nawk
macOS /usr/bin/awk
```

The exact matrix may vary by CI practicality.

Do not claim portability based solely on `gawk`.

---

# 55. Two portability questions

Portability has two distinct meanings here.

## A. Minifier implementation portability

Does the AWK Minifier itself run under supported AWK implementations?

## B. Output portability preservation

Does minifying a portable AWK input preserve its portability across supported interpreters?

Both need evidence.

---

# 56. Cross-interpreter test matrix

For portable fixtures, prove at least:

```text
original under interpreter X
    ==
minified under interpreter X
```

for each supported interpreter.

Also prove, where fixture behavior itself is portable:

```text
original outputs agree across interpreters
```

and:

```text
minified outputs agree across interpreters
```

Do not allow a nonportable fixture to create false confidence.

---

# 57. Test surfaces

The project should have at least these executable surfaces:

```text
1. modular maintained source set

2. dist/awk-minifier.dev.awk

3. dist/awk-minifier.awk

4. dist/awk-minifier.min.awk

5. temporary candidate-self-minified artifact
   (test-only)
```

The first four should receive the same public transformation contract wherever practical.

The fifth should receive self-hosting validation without becoming a release build input.

---

# 58. Test philosophy: more is more

This project should intentionally have a test suite that looks excessive relative to the source size.

That is desirable.

A 500-line transformer may deserve thousands of assertions.

Every byte removal rule is a potential semantic mutation.

The implementing process should assume:

> If a grammar boundary is not represented in tests, it is not safe merely because the code looks plausible.

---

# 59. Golden output tests

Maintain small fixtures with exact expected minified output.

Examples:

```text
tests/fixtures/regression/001-comment-full-line.awk
tests/expected/regression/001-comment-full-line.awk

tests/fixtures/regression/002-hash-in-string.awk
tests/expected/regression/002-hash-in-string.awk

tests/fixtures/regression/003-hash-in-regexp.awk
tests/expected/regression/003-hash-in-regexp.awk
```

Keep each fixture narrow.

A reviewer should understand what rule a failing fixture protects immediately.

---

# 60. Semantic equivalence tests

For each semantic fixture:

1. execute the original fixture using a selected AWK interpreter;
2. capture STDOUT;
3. capture STDERR;
4. capture exit status;
5. capture declared filesystem side effects;
6. minify the program;
7. execute the minified program in an equivalent controlled environment;
8. compare every declared observable.

Do not compare only STDOUT when the program has other effects.

---

# 61. Unit tests

Use unit tests where internal contracts are independently meaningful, such as:

- token classification;
- regexp/division contextual classification;
- separator requirement;
- regexp bracket-state handling;
- escape parity;
- operator longest match;
- newline classification.

Do not bind the entire suite to internal function names.

The public transformation contract remains primary.

---

# 62. Regression test rule

Every discovered bug gets a permanent regression test.

Workflow:

1. reduce failure to smallest reproducible AWK source;
2. commit a failing fixture;
3. implement the narrowest correction;
4. prove fixture passes;
5. prove full suite passes;
6. preserve fixture permanently.

Do not delete regression fixtures because the implementation later becomes "obviously correct."

---

# 63. Metamorphic tests

Investigate properties such as:

```text
minify(minify(x)) == minify(x)
```

```text
adding removable comments does not change behavior
```

```text
adding optional indentation does not change behavior
```

```text
safe formatting variants converge semantically
```

```text
comment removal never merges formerly distinct tokens
```

Metamorphic tests are valuable because they test classes of behavior rather than one hand-authored result.

---

# 64. Generated/fuzz testing

After deterministic coverage is mature, build a constrained valid-AWK generator.

Generate from a known-safe subgrammar:

- identifiers;
- numbers;
- strings;
- assignments;
- arithmetic;
- conditionals;
- loops;
- print;
- small regexps;
- pattern/action rules.

For each generated program:

1. execute original;
2. minify;
3. execute minified;
4. compare;
5. repeat across interpreters where practical.

Use deterministic seeds.

Persist minimized failures as ordinary regression fixtures.

Do not let fuzzing replace curated grammar tests.

---

# 65. Mutation-testing mindset

Ask whether the suite would fail if the implementation were deliberately broken in plausible ways:

- every slash classified as regexp;
- every slash classified as division;
- all newlines deleted;
- all newlines replaced by semicolon;
- all spaces deleted;
- `#` inside strings treated as comment;
- bracket-expression state ignored;
- escaped slash mishandled;
- any trailing backslash treated as continuation;
- comment deletion merged identifiers;
- two operators merged into a different operator;
- semicolon inserted before `}`;
- final character dropped;
- final newline mishandled.

If the suite would not fail, add tests.

---

# 66. Candidate self-minification test

A dedicated test should:

1. build candidate ordinary artifact;
2. use the candidate ordinary artifact as a minifier on itself;
3. validate generated AWK syntax under supported interpreters;
4. run the candidate-self-minified program against semantic fixtures;
5. evaluate idempotence if governed.

This proves dogfooding.

It does not create the production `.min.awk`.

---

# 67. Pinned-transformer build tests

Test the dependency boundary itself.

At minimum:

- missing `vendor/awk-minifier.awk` causes minified-artifact build failure;
- `make build` does not download the missing dependency;
- tampered vendored bytes fail `make deps-check`;
- `make deps` can converge back to declared state;
- development artifact does not depend on vendored minifier;
- ordinary artifact does not depend on vendored minifier;
- minified artifact does depend on prepared vendored minifier;
- all generated artifacts continue working after `vendor/` is removed;
- release assets do not reference `vendor/` at runtime.

---

# 68. Artifact-build tests

Validate:

- exact artifact names;
- exactly one adjacent `.sha256` per artifact;
- no stale `.256` current-build companions;
- shebang policy;
- executable mode if chosen;
- provenance header;
- deterministic source ordering;
- module-boundary newlines;
- ordinary full-line comment removal;
- minified artifact lineage;
- checksum verification;
- rebuild determinism when inputs and provenance inputs are unchanged.

---

# 69. Real-world corpus testing

Exercise the minifier against real AWK source.

Strong candidates include:

- `wesley-dean/awk-doxygen`;
- AWK scripts in related Wesley Dean repositories;
- carefully selected openly licensed AWK programs.

For each discovered issue:

- reduce it;
- retain a minimal regression fixture;
- record origin/context where useful;
- respect licenses.

Real-world corpus testing supplements grammar tests.

It does not replace them.

---

# 70. Input-record model caveat

AWK's normal record-processing model removes the record separator from `$0`.

A source-to-source transformer may care about:

- physical final newline;
- CRLF;
- exact newline boundaries.

The implementation process must explicitly study whether portable AWK exposes enough information for the project's desired source contract.

Do not accidentally claim byte-preserving input behavior that POSIX AWK cannot observe.

If the chosen product contract normalizes line endings or final-newline behavior, document and test it.

---

# 71. Line endings and encoding

Define a contract for:

- LF;
- CRLF;
- missing final newline;
- UTF-8;
- non-ASCII source;
- NUL bytes.

A practical contract may reject NUL and normalize line endings.

That is only an example.

Make the decision explicit.

Do not let host AWK implementation differences silently define it.

---

# 72. Shebang

Define whether the minifier preserves a leading AWK shebang.

Likely desired behavior:

- if input line 1 begins with `#!`, preserve it;
- do not treat it as an ordinary removable AWK comment;
- preserve bytes unless explicit normalization is governed;
- emit minified AWK after it.

Also distinguish:

```text
source language portability
```

from:

```text
shebang portability
```

A portable AWK program can still have a platform-specific shebang.

---

# 73. Diagnostics

Diagnostics go to STDERR.

Normal transformed source goes to STDOUT.

Never contaminate STDOUT with:

- warnings;
- debug output;
- progress;
- version banners;
- test diagnostics.

Diagnostics should include, where practical:

- `<stdin>`;
- physical line;
- column;
- concise error;
- relevant parser state.

Stable diagnostic wording may become part of regression fixtures.

---

# 74. Fail closed

Prefer:

```text
refuse ambiguous transformation
```

over:

```text
emit smaller source that might be wrong
```

Potential failure cases include:

- unterminated string;
- unterminated regexp;
- impossible lexer state;
- unsupported ambiguous grammar;
- malformed explicit continuation;
- invalid source where safe transformation cannot be established.

Do not produce partially transformed output and exit success after encountering a semantic uncertainty.

---

# 75. Performance

Correctness first.

However, avoid obviously pathological implementation choices.

AWK is expected to be more appropriate than Bash for character/token scanning.

Benchmark:

- small source;
- medium source;
- large documented source;
- long physical line;
- regexp-heavy source;
- string-heavy source;
- comment-heavy source.

Avoid spawning external commands per token or character.

---

# 76. Compression metrics

The project may report informational metrics:

```text
input bytes
output bytes
bytes removed
percentage reduction
input line count
output line count
```

Do not treat compression percentage as a correctness target.

A safer larger output is better than a smaller semantically fragile output.

---

# 77. Documentation

The maintained AWK source should follow the imported AWK documentation standard.

Use `awk-doxygen` as the Doxygen filter.

Acquire a pinned released `awk-doxygen` artifact through Bashdeps.

Do not generate docs with moving upstream source.

Documentation generation should be offline after dependency preparation.

Generated `doc/reference/` remains generated state.

---

# 78. `awk-doxygen` as repository model

Study `wesley-dean/awk-doxygen`.

Especially reuse:

- portable-AWK posture;
- conservative recognition;
- small behavior-focused fixtures;
- `AWK_BIN` selection;
- `gawk` + `mawk` CI baseline;
- pinned released tooling for stable generation;
- current-source canary;
- exact-release canary;
- generated artifact/checksum boundary;
- ADR discipline;
- `doc/decisions.md` summaries.

AWK Minifier should be more exhaustive in semantic testing because it transforms executable programs.

---

# 79. `bootstrap`, `template-bash`, and `bashdeps` as models

Study:

https://github.com/wesley-dean/bootstrap

https://github.com/wesley-dean/template-bash

https://github.com/wesley-dean/bashdeps

Reuse appropriate patterns for:

- Make orchestration;
- explicit dependency acquisition;
- offline verification;
- modular source;
- generated standalone artifacts;
- checksums;
- release provenance;
- release attestations;
- dependency threat boundaries;
- documentation-led development.

Do not transplant Bash-specific runtime architecture into the AWK product.

---

# 80. Threat model

Update the repository threat model for this product.

Relevant concerns include:

- untrusted AWK input;
- adversarial lexer cases;
- semantic corruption of downstream programs;
- executing downloaded build dependencies;
- dependency tampering;
- moving URLs;
- malformed standards imports;
- unexpected network access;
- CI release credentials;
- release-asset substitution;
- temporary-file races in tests/build;
- command injection through filenames used by repository tooling;
- locale-dependent parsing;
- denial of service via enormous lines;
- quadratic scanning;
- malicious source designed to trigger parser state bugs.

The minifier itself must treat STDIN as data.

It must not execute, source, or shell-evaluate the input program.

Only trusted test fixtures are executed by the test suite.

---

# 81. Release engineering

Use the current repository's Conventional Commit / semantic version governance unless intentionally superseded.

Release validation should happen before publication.

Release assets should include:

```text
awk-minifier.dev.awk
awk-minifier.dev.awk.sha256
awk-minifier.awk
awk-minifier.awk.sha256
awk-minifier.min.awk
awk-minifier.min.awk.sha256
```

Where the repository already uses provenance/attestation, extend that to the exact AWK assets.

Do not release template Bash artifacts once the project conversion is complete.

---

# 82. Post-release canary

Adopt the `awk-doxygen` idea.

After release:

1. download the exact published AWK Minifier artifacts;
2. download checksum companions;
3. verify bytes;
4. run the exact release artifacts through representative transformation tests;
5. run semantic equivalence tests;
6. fail visibly if packaging differs from what source-level CI implied.

Do not substitute a tag checkout for testing the released asset.

Packaging is part of the consumer contract.

---

# 83. `AGENTS.md` changes

Update `AGENTS.md` so future agents are told:

- product code is portable AWK;
- read imported standards under `doc/standards/`;
- synchronized standards/examples are not locally editable;
- standards are normative, examples illustrative;
- source is modular;
- build order is explicit;
- output is STDIN-to-STDOUT only;
- portability claims require multi-AWK evidence;
- slash classification and newline rules are high-risk;
- new transformations require regression tests;
- every bug requires a fixture;
- self-minification is a test only;
- pinned `vendor/awk-minifier.awk` builds `.min.awk`;
- current candidate must never replace that trusted build role implicitly;
- Make target network boundaries must remain visible;
- architecture changes require ADR review;
- update `doc/decisions.md` for changed decisions.

---

# 84. README conversion

Replace the starter README with an AWK Minifier README.

It should cover:

- project purpose;
- streaming contract;
- usage;
- portability baseline;
- artifact flavors;
- checksums;
- semantic-preservation philosophy;
- supported and unsupported syntax;
- build workflow;
- dependency workflow;
- standards governance;
- testing strategy;
- self-minification dogfood test;
- pinned build transformer;
- release verification;
- inspiration/credit to Bash-Minifier;
- related projects.

Do not leave stale `template-bash` claims.

---

# 85. Repository hygiene

Search every repository-facing surface for inherited template content:

- README;
- CONTRIBUTING;
- SUPPORT;
- SECURITY;
- issue templates;
- pull request template;
- workflows;
- badges;
- Make variables;
- source names;
- release asset names;
- docs;
- test names;
- comments.

Do not leave `template-bash`, plugin/noop behavior, or Bash runtime claims where they no longer apply.

This cleanup is part of product conversion, not unrelated beautification.

---

# 86. Proposed new/revised ADR areas

The implementing process must inspect current ADRs before assigning numbers.

Likely required decisions include:

## Product runtime and portability

Supersede the Bash runtime ADR.

## Modular AWK source assembly

Refine the template modularity decisions.

## Streaming public interface

STDIN input, STDOUT output, STDERR diagnostics.

## AWK lexical/grammar recognition

Regexp/division, strings, comments, separators, fail-closed behavior.

## Three AWK artifact flavors

Refine existing artifact ADR.

## Pinned released self-dependency for minified build

Record the trusted transformer boundary.

## First-release bootstrap strategy

Resolve the chicken-and-egg problem explicitly.

## Observable semantic-equivalence testing

Strengthen the existing behavior-test ADR.

## Self-minification as test-only dogfooding

Prevent future drift into candidate-self-built releases.

## Imported reusable standards

Document Bashdeps-managed project governance and precedence.

Do not create duplicate ADRs where an existing decision can be cleanly amended/superseded.

---

# 87. Testing document rewrite

`doc/testing.md` should become specific to AWK Minifier.

It should describe:

- modular source surface;
- three release artifact surfaces;
- golden transformation fixtures;
- semantic-equivalence fixtures;
- interpreter matrix;
- candidate self-minification;
- pinned transformer validation;
- metamorphic properties;
- fuzzing;
- side-effect capture;
- invalid-input behavior;
- release asset canary;
- portability evidence.

Keep the existing useful principle:

> Prefer focused tests and durable invariants over test-count snapshots.

---

# 88. Implementation sequence

The next ChatGPT process must create its own detailed plan.

A recommended sequence is:

## Phase 0: discovery

- inspect repository;
- inspect all ADRs;
- inspect coding standards;
- inspect model repos;
- inspect Bash-Minifier;
- inspect POSIX AWK;
- identify governance conflicts;
- propose plan.

No implementation yet.

## Phase 1: governance conversion

- add/supersede ADRs;
- update `doc/decisions.md`;
- establish product contract;
- establish portability;
- establish build transformer trust model;
- establish first-release bootstrap;
- establish test contract.

## Phase 2: standards materialization

- pin coding_standards;
- create standards manifest;
- import selected standards;
- import selected examples;
- add `standards` / `standards-check`;
- update AGENTS.

## Phase 3: repository conversion

- remove Bash example product;
- remove plugin example;
- rename build variables;
- update README/docs/workflows;
- establish AWK module structure.

## Phase 4: lexer/tokenizer foundation

- strings;
- comments;
- tokens;
- escapes;
- regexp state;
- operator recognition;
- line tracking.

## Phase 5: slash and newline grammar

- regexp/division classification;
- logical separators;
- semicolon insertion;
- whitespace preservation;
- fail-closed cases.

## Phase 6: semantic harness

- original/minified execution;
- artifact matrix;
- interpreter matrix;
- side effects.

## Phase 7: exhaustive regression expansion

- grammar edge cases;
- Bash-Minifier-inspired boundary cases;
- generated/fuzz tests;
- real-world corpus.

## Phase 8: build products

- `.dev.awk`;
- `.awk`;
- `.min.awk` using pinned vendor release;
- checksums;
- provenance;
- determinism.

## Phase 9: self-minification dogfood

- candidate self-minification;
- idempotence if governed;
- never use candidate as build transformer.

## Phase 10: releases/canaries

- six release assets;
- attestations;
- exact-release canary;
- bootstrap transition.

---

# 89. Detailed plan required before implementation

The next session must produce a plan containing:

1. current repository state;
2. branch and release state;
3. inherited governance analysis;
4. ADR conflicts;
5. proposed ADR changes;
6. exact coding-standards upstream ref;
7. exact imported standard/example files;
8. exact destination paths;
9. Bashdeps manifests and target behavior;
10. AWK source modules;
11. source-order rationale;
12. lexer states;
13. token model;
14. regexp/division strategy;
15. newline/separator strategy;
16. invalid-input strategy;
17. portability matrix;
18. test architecture;
19. artifact build lineage;
20. pinned-transformer version strategy;
21. first-real-release bootstrap plan;
22. release workflow;
23. canary strategy;
24. documentation plan;
25. threat-model changes;
26. migration/removal of template artifacts;
27. material assumptions;
28. unresolved material questions.

Do not begin coding until this plan exists.

---

# 90. Material assumptions the next process should verify

Likely assumptions include:

- POSIX AWK is the intended product floor;
- the project should avoid GNU-specific implementation syntax;
- Bash remains acceptable for Make recipes/test harnesses;
- modular AWK source is preferred;
- core source ordering is explicit;
- product interface remains STDIN/STDOUT only;
- `awk-minifier.min.awk` must use pinned released transformer bytes;
- candidate self-minification is test-only;
- all three release flavors are public products;
- standards examples preserve relative paths;
- imported standards are not edited locally;
- build remains network-free;
- release assets are generated state.

If any assumption is contradicted by current Accepted governance, surface the conflict.

---

# 91. Minimum initial lexical fixture list

At minimum:

```awk
# comment
BEGIN { print "hello" }
```

```awk
BEGIN { print "foo # bar" } # comment
```

```awk
/foo/ { print }
```

```awk
/foo\/bar/ { print }
```

```awk
/[a-z/#]+/ { print }
```

```awk
$0 ~ /foo/ { print }
```

```awk
$0 !~ /foo/ { print }
```

```awk
BEGIN { print 10 / 2 }
```

```awk
BEGIN { x = 10; x /= 2; print x }
```

```awk
function double(x) {
    return x * 2
}

BEGIN {
    print double(4)
}
```

```awk
{
    counts[$1]++
}

END {
    for (key in counts) {
        print key, counts[key]
    }
}
```

```awk
{
    print $1 ? "yes" : "no"
}
```

```awk
BEGIN {
    printf "%s: %d\n", \
        "value", 42
}
```

```awk
/foo/ { print "foo" }
/bar/ { print "bar" }
```

```awk
/foo/
```

```awk
{ print $1 }
```

These are merely the beginning.

---

# 92. Minimum negative fixture list

Include:

- unterminated string;
- unterminated regexp;
- dangling escape;
- malformed bracket expression where interpreter behavior is relevant;
- invalid token adjacency;
- incomplete expression;
- malformed continuation;
- ambiguous/unsupported construct if the parser intentionally narrows scope.

Define whether the minifier rejects invalid source or merely detects states required for safe transformation.

Prefer explicit failure over silent corruption.

---

# 93. Build provenance

Provenance should be comments, not executable AWK state.

Useful fields:

```text
project
version
build date
build commit
source files
build transformer identity for .min.awk
```

Do not introduce AWK variables solely for build metadata.

A build transformer identity comment in `.min.awk` may be valuable because that artifact is explicitly derived using a pinned older release.

If adopted, define the exact field contract in an ADR.

---

# 94. Build date determinism

Follow the template/Bootstrap practice of deriving build date from the Git commit rather than wall-clock time where practical.

Dirty source should not falsely claim pristine provenance.

Preserve or adapt the current `-dirty` commit-marker convention if appropriate.

---

# 95. Checksums

Produce standard checksum files:

```text
<sha256>  <filename>
```

Support common environments by detecting:

```text
sha256sum
```

or:

```text
shasum -a 256
```

Do not assume GNU coreutils on macOS.

Checksum generation should stage output and publish only after success.

---

# 96. Build atomicity

Generated artifacts should be written to temporary sibling paths and renamed into place after successful generation.

Do not leave a truncated final artifact after a failed transformation.

This applies especially to:

```text
awk-minifier.min.awk
```

because a transformer failure must not publish partial output.

---

# 97. Standards and documentation ordering

Before modifying product source, the implementation process should:

1. materialize standards;
2. read the imported standards;
3. read applicable examples;
4. then write product code.

The standards are intended for both humans and coding agents.

Do not import them only after implementation and treat them as documentation decoration.

---

# 98. Licensing and attribution

Study the current repository license and Bash-Minifier's MIT license.

If no Bash-Minifier implementation code is copied, still credit the project as inspiration and historical precedent.

If any implementation code is adapted, preserve required notices.

Do not imply official affiliation with Bash-Minifier's maintainer.

---

# 99. Definition of done

Version 1 should not be considered complete until:

- repository governance describes AWK, not template Bash;
- relevant inherited ADRs are preserved/refined/superseded deliberately;
- `doc/decisions.md` is accurate;
- required coding standards are imported through Bashdeps;
- required examples are imported through Bashdeps;
- exact relative paths are preserved;
- standards verification is offline;
- product code is modular AWK;
- modular source executes as a complete program;
- product reads only STDIN;
- product writes successful output only to STDOUT;
- diagnostics use STDERR;
- POSIX portability baseline is documented;
- regexp/division handling is governed and heavily tested;
- newline/separator logic is governed and heavily tested;
- comments/strings/regexps/escapes are heavily tested;
- semantic-equivalence harness exists;
- multiple AWK implementations are exercised;
- development artifact exists;
- ordinary artifact exists;
- minified artifact exists;
- each has a `.sha256`;
- `.min.awk` is built by a pinned released minifier;
- candidate self-minification is test-only;
- self-minification test passes;
- first-release bootstrap is explicitly documented;
- all shipped artifacts pass the same public behavior suite;
- released artifacts do not require `vendor/`;
- builds are network-free after preparation;
- dependency tampering is tested;
- standards tampering is tested;
- documentation is generated using pinned filters;
- release workflow publishes only the AWK artifacts;
- post-release canary tests exact downloadable assets;
- repository-facing template residue is removed;
- threat model is product-specific;
- README accurately describes real behavior;
- no unsupported syntax is silently advertised as supported.

---

# 100. Explicit instructions to the implementing ChatGPT session

Do not:

- start coding before reading governance;
- treat this repository as empty;
- delete inherited ADRs without evaluating them;
- preserve Bash runtime governance after product runtime becomes AWK;
- preserve plugin architecture by inertia;
- implement the lexer in Bash;
- add a Bash runtime wrapper without a new requirement;
- add file input/output options to the baseline interface;
- implement minification with regex replacements alone;
- treat every `/` as regexp;
- treat every `/` as division;
- replace every newline with semicolon;
- delete every whitespace character;
- strip comments without lexer state;
- execute arbitrary input AWK during minification;
- use the candidate to create the production minified artifact;
- confuse self-minification testing with build trust;
- trust the existing v0.0.1 release as an AWK bootstrap;
- fetch standards directly from moving `main` during build;
- flatten imported standards;
- place examples outside `doc/standards/examples/`;
- edit synchronized standards locally;
- let `make build` access the network;
- let `make deps-check` repair state;
- release without semantic testing;
- test only gawk;
- weaken tests to accommodate a transformation;
- optimize for maximum compression at the expense of explanation and evidence.

---

# 101. References the implementation process must inspect

## Target project

https://github.com/wesley-dean/awk-minifier

## Reusable standards

https://github.com/wesley-dean/coding_standards

Read its `README.md` before materializing standards.

## AWK documentation model

https://github.com/wesley-dean/awk-doxygen

## Bash source/build model

https://github.com/wesley-dean/bootstrap

## Bash starter model

https://github.com/wesley-dean/template-bash

## Dependency materializer

https://github.com/wesley-dean/bashdeps

## Bash Doxygen model

https://github.com/wesley-dean/bash-doxygen

## Minifier inspiration

https://github.com/Zuzzuc/Bash-minifier

Inspect its source, current tests, release process, and historical correctness issues.

## AWK specification

Current applicable POSIX AWK specification.

A historically relevant URL is:

https://pubs.opengroup.org/onlinepubs/9699919799/utilities/awk.html

Verify whether a newer applicable POSIX publication is available.

## GNU awk reference

https://www.gnu.org/software/gawk/manual/

Use it as implementation-specific documentation and portability guidance, not as the sole language standard.

---

# 102. Closing instruction

Treat AWK Minifier as a small compiler-like source transformation tool.

Its implementation may be compact.

Its reasoning, tests, and governance should not be.

The project is successful when a reviewer can answer:

- What AWK syntax do we claim to support?
- Why is this slash a regexp rather than division?
- Why is this newline removable?
- Why is this space removable?
- Why does deleting this comment not merge tokens?
- Which AWK interpreters support the claim?
- Which exact transformer bytes built the minified release artifact?
- Which standards governed the source?
- Which tests prove the transformed program still behaves the same?
- How was the first trusted release bootstrapped?
- Can the current candidate minify itself successfully without being trusted to build itself?

with evidence from ADRs, source, manifests, tests, build artifacts, and release records.

Prefer a preserved space over a tokenization bug.

Prefer a preserved newline over a changed program.

Prefer a clear unsupported error over speculative parsing.

Prefer a slightly larger artifact over an unprovable optimization.

Prefer explicit pinned tooling over circular self-trust.

Prefer thousands of focused tests over one reassuring demo.

The final contract should be:

> For the explicitly supported AWK language and portability boundary, AWK Minifier accepts source on STDIN, emits a smaller semantically equivalent AWK program on STDOUT, and provides unusually strong evidence that the transformation is safe.
