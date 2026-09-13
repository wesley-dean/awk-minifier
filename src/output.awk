## @file src/output.awk
## @brief Buffered output support for atomic transformation publication.

## @fn emit(text)
## @brief Appends text to the buffered transformed output.
## @details
## Output remains in memory until the complete input has been validated.  This
## keeps malformed input from producing partial transformed source on STDOUT.
##
## @param text Text to append.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing.
function emit(text) {
  output_count++
  output_chunk[output_count] = text
}

## @fn emit_pending_space()
## @brief Emits one deferred horizontal separator when one is required.
## @details
## Horizontal whitespace outside strings and regexp literals is delayed until a
## following token is known to exist.  Leading indentation never sets
## `pending_space`, while explicit continuation and keyword-continuation newlines
## may request a separator directly.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing.
function emit_pending_space() {
  if (pending_space) {
    emit(" ")
  }
  pending_space = 0
}

## @fn emit_shebang_newline()
## @brief Emits the one physical newline retained by the transformer.
## @details
## A first-line shebang must terminate before the AWK program begins.  ADR-023
## otherwise requires successful transformed source to contain no physical
## newlines.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing.
function emit_shebang_newline() {
  pending_space = 0
  emit("\n")
  line_has_content = 0
}

## @fn emit_statement_separator()
## @brief Emits a semicolon for a significant newline terminator.
## @details
## Newlines that are not grammar-optional are represented explicitly with `;` so
## statements and top-level rules remain separated without retaining a physical
## line boundary.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing.
function emit_statement_separator() {
  pending_space = 0
  if (last_normal_char != ";") {
    emit(";")
    last_normal_char = ";"
  }
  line_has_content = 0
}
