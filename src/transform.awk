## @file src/transform.awk
## @brief Provides the main lexical transformation loop for AWK Minifier.
## @details
## This module coordinates lexical scanners, grammar context, buffered output,
## slash classification, comment removal, whitespace reduction, and ADR-023
## newline handling.  It consumes the complete source previously buffered by
## `src/main.awk` and never publishes output directly; final publication remains
## the responsibility of the END rule after transformation succeeds.

## @fn transform_source()
## @brief Transforms the buffered AWK source according to ADR-023.
## @details
## Comments outside literals are removed, horizontal whitespace is collapsed, and
## physical newlines are classified using structural context.  Grammar-optional
## newlines disappear, statement and rule terminators become semicolons, explicit
## backslash-newline continuation disappears, and only a first-line shebang keeps
## a physical newline.  Slash interpretation remains operand-context-sensitive so
## division and regexp literals are not classified by character value alone.
## @local i Current source position.
## @local n Total source length.
## @local ch Current source character.
## @local nextch Following source character.
## @local start Start position of the current token.
## @local token Current identifier or numeric token.
## @par STDIN
## Nothing is read directly from STDIN; the global `source` buffer is consumed.
## @par STDOUT
## Nothing is written immediately; transformed bytes are buffered through `emit`.
## @par STDERR
## Nothing is written immediately; malformed input is recorded through `fail`.
## @returns No meaningful value; callers use the function for its side effects.
function transform_source(    i, n, ch, nextch, start, token) {
  n = length(source)
  reset_transform_context()

  i = 1
  while (i <= n && !failed) {
    ch = substr(source, i, 1)
    nextch = substr(source, i + 1, 1)

    if (i == 1 && ch == "#" && nextch == "!") {
      while (i <= n && substr(source, i, 1) != "\n") {
        emit(substr(source, i, 1))
        i++
      }
      line_has_content = 1
      if (i <= n) {
        emit_shebang_newline()
        i++
      }
      expect_operand = 1
      last_normal_char = ""
      newline_optional_after = 0
      newline_space_after = 0
      continue
    }

    if (is_horizontal_space(ch)) {
      if (line_has_content) {
        pending_space = 1
      }
      i++
      continue
    }

    if (ch == "\\" && nextch == "\n") {
      pending_space = 1
      line_has_content = 0
      i += 2
      continue
    }

    if (ch == "\n") {
      if (!line_has_content) {
        i++
        continue
      }

      if (!remaining_source_has_token(i + 1, n)) {
        pending_space = 0
        line_has_content = 0
        i++
        continue
      }

      if (newline_optional_after) {
        if (newline_space_after) {
          pending_space = 1
        } else {
          pending_space = 0
        }
        line_has_content = 0
      } else {
        emit_statement_separator()
        expect_operand = 1
      }

      newline_optional_after = 0
      newline_space_after = 0
      i++
      continue
    }

    if (ch == "#") {
      i = skip_comment(i, n)
      continue
    }

    if (ch == "\"") {
      i = scan_string(i, n)
      last_normal_char = "\""
      newline_optional_after = 0
      newline_space_after = 0
      continue
    }

    if (is_identifier_start(ch)) {
      start = i
      i++
      while (i <= n && is_identifier_part(substr(source, i, 1))) {
        i++
      }
      token = substr(source, start, i - start)
      emit_pending_space()
      emit(token)
      line_has_content = 1
      note_identifier_context(token)
      expect_operand = keyword_expects_operand(token)
      last_normal_char = substr(token, length(token), 1)
      continue
    }

    if (ch ~ /[0-9]/ || (ch == "." && nextch ~ /[0-9]/)) {
      start = i
      i++
      while (i <= n && substr(source, i, 1) ~ /[A-Za-z0-9_.]/) {
        i++
      }
      emit_pending_space()
      token = substr(source, start, i - start)
      emit(token)
      line_has_content = 1
      expect_operand = 0
      last_normal_char = substr(token, length(token), 1)
      newline_optional_after = 0
      newline_space_after = 0
      continue
    }

    if (ch == "/") {
      if (nextch == "=") {
        emit_pending_space()
        emit("/=")
        line_has_content = 1
        expect_operand = 1
        last_normal_char = "="
        newline_optional_after = 0
        newline_space_after = 0
        i += 2
        continue
      }
      if (expect_operand) {
        i = scan_regexp(i, n)
        last_normal_char = "/"
        newline_optional_after = 0
        newline_space_after = 0
        continue
      }
      emit_pending_space()
      emit("/")
      line_has_content = 1
      expect_operand = 1
      last_normal_char = "/"
      newline_optional_after = 0
      newline_space_after = 0
      i++
      continue
    }

    emit_pending_space()

    if ((ch == "+" || ch == "-") && nextch == ch) {
      emit(ch ch)
      line_has_content = 1
      if (expect_operand) {
        expect_operand = 1
      } else {
        expect_operand = 0
      }
      last_normal_char = ch
      newline_optional_after = 0
      newline_space_after = 0
      i += 2
      continue
    }

    if ((ch == "=" || ch == "!" || ch == "<" || ch == ">" ||
         ch == "&" || ch == "|") && nextch == "=") {
      emit(ch nextch)
      line_has_content = 1
      expect_operand = 1
      last_normal_char = nextch
      newline_optional_after = 0
      newline_space_after = 0
      i += 2
      continue
    }

    if ((ch == "&" && nextch == "&") || (ch == "|" && nextch == "|") ||
        (ch == "!" && nextch == "~") || (ch == "*" && nextch == "*")) {
      emit(ch nextch)
      line_has_content = 1
      expect_operand = 1
      last_normal_char = nextch
      newline_optional_after = ((ch == "&" && nextch == "&") ||
                                (ch == "|" && nextch == "|"))
      newline_space_after = 0
      i += 2
      continue
    }

    emit(ch)
    line_has_content = 1
    note_punctuation_context(ch)
    last_normal_char = ch
    i++
  }
}
