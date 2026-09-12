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
## following token is known to exist.  Leading and trailing horizontal whitespace
## is therefore discarded, while token-separating whitespace collapses to one
## ASCII space.
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
  if (pending_space && line_has_content) {
    emit(" ")
  }
  pending_space = 0
}

## @fn emit_newline()
## @brief Emits a physical newline while discarding pending trailing whitespace.
## @details
## Newlines are deliberately preserved because AWK grammar permits newlines to
## separate statements and patterns.  The first implementation does not trade
## that safety margin for smaller output.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing.
function emit_newline() {
  pending_space = 0
  emit("\n")
  line_has_content = 0
}
