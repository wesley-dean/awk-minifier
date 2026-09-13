## @file src/lexer.awk
## @brief Provides lexical scanners for portable AWK source.
## @details
## This module recognizes identifier boundaries, operand-sensitive keywords,
## string literals, regexp literals, and comments.  Literal scanners preserve
## literal bytes and reject backslash-newline inside string or regexp literals
## because tested AWK implementations do not agree on that construct's semantics.
## Slash classification itself remains contextual and is coordinated by the
## transformation loop.

## @fn is_identifier_start(ch)
## @brief Reports whether a character may begin an AWK identifier.
## @details
## The recognizer intentionally uses the portable ASCII identifier subset already
## established by the project rather than locale-sensitive character classes.
## @param ch One-character string.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns A numeric truth value.
function is_identifier_start(ch) {
  return (ch ~ /[A-Za-z_]/)
}

## @fn is_identifier_part(ch)
## @brief Reports whether a character may continue an AWK identifier.
## @details
## Digits are accepted after the first identifier character while the same
## portable ASCII naming policy used by `is_identifier_start` is preserved.
## @param ch One-character string.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns A numeric truth value.
function is_identifier_part(ch) {
  return (ch ~ /[A-Za-z0-9_]/)
}

## @fn keyword_expects_operand(word)
## @brief Reports whether a keyword is normally followed by an expression.
## @details
## The result is used to distinguish regexp literal delimiters from division
## operators.  Keywords that introduce or resume an expression return true;
## ordinary identifiers return false.  This helper is contextual recognition, not
## a complete AWK grammar classifier.
## @param word Identifier token.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns A numeric truth value.
function keyword_expects_operand(word) {
  return (word == "print" || word == "printf" || word == "return" ||
          word == "if" || word == "while" || word == "for" ||
          word == "do" || word == "else" || word == "delete" ||
          word == "in")
}

## @fn scan_string(pos, length_source)
## @brief Copies one double-quoted string literal without rewriting its content.
## @details
## The function consumes the global buffered `source`, writes transformed bytes to
## the global output buffer through `emit`, and tracks escapes until the closing
## quote.  Backslash-newline inside a string is rejected because GNU/Linux AWKs
## and the macOS system AWK do not provide a uniform behavior for that source
## construct.  An unescaped newline or EOF before the closing quote records the
## ordinary unterminated-string failure.
## @param pos Position of the opening quote.
## @param length_source Total source length.
## @local i Current source position.
## @local ch Current source character.
## @local nextch Following source character.
## @local escaped Whether the previous character was a backslash.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately; bytes are buffered through `emit`.
## @par STDERR
## Nothing is written immediately; malformed or non-portable input is recorded
## through `fail`.
## @returns Position immediately after the closing quote, or after the failing
## position when the string is malformed or non-portable.
function scan_string(pos, length_source,    i, ch, nextch, escaped) {
  emit_pending_space()
  emit("\"")
  line_has_content = 1
  escaped = 0

  for (i = pos + 1; i <= length_source; i++) {
    ch = substr(source, i, 1)
    nextch = substr(source, i + 1, 1)

    if (ch == "\\" && nextch == "\n") {
      fail("backslash-newline inside string literal is not portable")
      return i + 2
    }

    if (ch == "\n" && !escaped) {
      fail("unterminated string literal")
      return i
    }

    emit(ch)
    if (escaped) {
      escaped = 0
    } else if (ch == "\\") {
      escaped = 1
    } else if (ch == "\"") {
      expect_operand = 0
      newline_optional_after = 0
      newline_space_after = 0
      return i + 1
    }
  }

  fail("unterminated string literal")
  return length_source + 1
}

## @fn scan_regexp(pos, length_source)
## @brief Copies one regexp literal without rewriting its content.
## @details
## The function consumes the global buffered `source`, writes transformed bytes to
## the global output buffer through `emit`, and tracks escapes until the closing
## slash.  Backslash-newline inside a regexp is rejected because GNU/Linux AWKs
## and the macOS system AWK do not provide a uniform behavior for that source
## construct.  An unescaped newline or EOF before the closing slash records the
## ordinary unterminated-regexp failure.
## @param pos Position of the opening slash.
## @param length_source Total source length.
## @local i Current source position.
## @local ch Current source character.
## @local nextch Following source character.
## @local escaped Whether the previous character was a backslash.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately; bytes are buffered through `emit`.
## @par STDERR
## Nothing is written immediately; malformed or non-portable input is recorded
## through `fail`.
## @returns Position immediately after the closing slash, or after the failing
## position when the regexp is malformed or non-portable.
function scan_regexp(pos, length_source,    i, ch, nextch, escaped) {
  emit_pending_space()
  emit("/")
  line_has_content = 1
  escaped = 0

  for (i = pos + 1; i <= length_source; i++) {
    ch = substr(source, i, 1)
    nextch = substr(source, i + 1, 1)

    if (ch == "\\" && nextch == "\n") {
      fail("backslash-newline inside regexp literal is not portable")
      return i + 2
    }

    if (ch == "\n" && !escaped) {
      fail("unterminated regexp literal")
      return i
    }

    emit(ch)
    if (escaped) {
      escaped = 0
    } else if (ch == "\\") {
      escaped = 1
    } else if (ch == "/") {
      expect_operand = 0
      newline_optional_after = 0
      newline_space_after = 0
      return i + 1
    }
  }

  fail("unterminated regexp literal")
  return length_source + 1
}

## @fn skip_comment(pos, length_source)
## @brief Skips a comment body while leaving its terminating newline to context.
## @details
## The newline is not consumed because the transformation loop must decide whether
## that physical line ended a statement, ended a rule, or occurred in a grammar
## position where the newline is optional.  Pending horizontal space before the
## comment is discarded.
## @param pos Position of the comment marker.
## @param length_source Total source length.
## @local i Current source position.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns Position of the newline ending the comment, or one past input.
function skip_comment(pos, length_source,    i) {
  pending_space = 0
  for (i = pos; i <= length_source; i++) {
    if (substr(source, i, 1) == "\n") {
      return i
    }
  }
  return length_source + 1
}
