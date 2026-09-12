## @file src/lexer.awk
## @brief Conservative lexical transformer for portable AWK source.

## @fn is_identifier_start(ch)
## @brief Reports whether a character may begin an AWK identifier.
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
## The result is used only to distinguish a regexp literal delimiter from a
## division operator.  Keywords that introduce or resume an expression return
## true; ordinary identifiers return false.
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
## @param pos Position of the opening quote.
## @param length_source Total source length.
## @local i Current source position.
## @local ch Current source character.
## @local escaped Whether the previous character was a backslash.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately; bytes are buffered through `emit`.
## @par STDERR
## Nothing is written immediately; malformed input is recorded through `fail`.
## @returns Position immediately after the closing quote, or after the failing
## position when the string is malformed.
function scan_string(pos, length_source,    i, ch, escaped) {
  emit_pending_space()
  emit("\"")
  line_has_content = 1
  escaped = 0

  for (i = pos + 1; i <= length_source; i++) {
    ch = substr(source, i, 1)
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
      return i + 1
    }
  }

  fail("unterminated string literal")
  return length_source + 1
}

## @fn scan_regexp(pos, length_source)
## @brief Copies one regexp literal without rewriting its content.
## @param pos Position of the opening slash.
## @param length_source Total source length.
## @local i Current source position.
## @local ch Current source character.
## @local escaped Whether the previous character was a backslash.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately; bytes are buffered through `emit`.
## @par STDERR
## Nothing is written immediately; malformed input is recorded through `fail`.
## @returns Position immediately after the closing slash, or after the failing
## position when the regexp is malformed.
function scan_regexp(pos, length_source,    i, ch, escaped) {
  emit_pending_space()
  emit("/")
  line_has_content = 1
  escaped = 0

  for (i = pos + 1; i <= length_source; i++) {
    ch = substr(source, i, 1)
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
      return i + 1
    }
  }

  fail("unterminated regexp literal")
  return length_source + 1
}

## @fn skip_comment(pos, length_source)
## @brief Skips a comment body while preserving its terminating newline.
## @param pos Position of the comment marker.
## @param length_source Total source length.
## @local i Current source position.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written immediately.
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

## @fn transform_source()
## @brief Transforms the buffered AWK source conservatively.
## @details
## The transformer removes comments outside strings and regexp literals, removes
## indentation and trailing horizontal whitespace, and collapses other horizontal
## whitespace runs to one ASCII space.  Physical newlines are preserved.  Slash
## interpretation uses expression context so regexp constants are not confused
## with division operators.
## @local i Current source position.
## @local n Total source length.
## @local ch Current source character.
## @local nextch Following source character.
## @local start Start position of the current token.
## @local token Current identifier token.
## @local continued Whether the current physical newline follows a continuation.
## @par STDIN
## Source has already been buffered from STDIN by the ordinary input rule.
## @par STDOUT
## Nothing is written immediately; transformed bytes are buffered.
## @par STDERR
## Nothing is written immediately; malformed input is recorded through `fail`.
## @returns Nothing.
function transform_source(    i, n, ch, nextch, start, token, continued) {
  n = length(source)
  expect_operand = 1
  line_has_content = 0
  pending_space = 0
  last_normal_char = ""

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
        emit_newline()
        i++
      }
      expect_operand = 1
      last_normal_char = ""
      continue
    }

    if (ch == " " || ch == "\t" || ch == "\r" || ch == "\f" || ch == "\v") {
      pending_space = 1
      i++
      continue
    }

    if (ch == "\n") {
      continued = (last_normal_char == "\\")
      emit_newline()
      if (!continued) {
        expect_operand = 1
      }
      last_normal_char = ""
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
      continue
    }

    if (ch == "/") {
      if (nextch == "=") {
        emit_pending_space()
        emit("/=")
        line_has_content = 1
        expect_operand = 1
        last_normal_char = "="
        i += 2
        continue
      }
      if (expect_operand) {
        i = scan_regexp(i, n)
        last_normal_char = "/"
        continue
      }
      emit_pending_space()
      emit("/")
      line_has_content = 1
      expect_operand = 1
      last_normal_char = "/"
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
      i += 2
      continue
    }

    if ((ch == "=" || ch == "!" || ch == "<" || ch == ">" ||
         ch == "&" || ch == "|") && nextch == "=") {
      emit(ch nextch)
      line_has_content = 1
      expect_operand = 1
      last_normal_char = nextch
      i += 2
      continue
    }

    if ((ch == "&" && nextch == "&") || (ch == "|" && nextch == "|") ||
        (ch == "!" && nextch == "~") || (ch == "*" && nextch == "*")) {
      emit(ch nextch)
      line_has_content = 1
      expect_operand = 1
      last_normal_char = nextch
      i += 2
      continue
    }

    emit(ch)
    line_has_content = 1
    last_normal_char = ch

    if (ch == ")" || ch == "]") {
      expect_operand = 0
    } else if (ch == "}") {
      expect_operand = 0
    } else if (ch == "(" || ch == "[" || ch == "{" || ch == "," ||
               ch == ";" || ch == "?" || ch == ":" || ch == "=" ||
               ch == "+" || ch == "-" || ch == "*" || ch == "%" ||
               ch == "^" || ch == "~" || ch == "!" || ch == "<" ||
               ch == ">" || ch == "$" || ch == "|") {
      expect_operand = 1
    } else {
      expect_operand = 0
    }

    i++
  }
}
