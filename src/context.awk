## @file src/context.awk
## @brief Tracks structural context used to classify AWK source newlines.
## @details
## This module owns the small amount of grammar state required by ADR-023.  It
## distinguishes control-statement and function-definition parentheses, tracks
## brace depth and pending `do ... while` statements, records whether a following
## newline is grammar-optional, and identifies whether meaningful source remains
## after a candidate terminator.  It deliberately does not attempt to parse the
## complete AWK grammar.

## @fn is_horizontal_space(ch)
## @brief Reports whether a character is horizontal source whitespace.
## @details
## Physical newline is intentionally excluded because ADR-023 gives newline its
## own grammar-sensitive classification path.
## @param ch One-character string.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns A numeric truth value.
function is_horizontal_space(ch) {
  return (ch == " " || ch == "\t" || ch == "\r" ||
          ch == "\f" || ch == "\v")
}

## @fn remaining_source_has_token(pos, length_source)
## @brief Reports whether significant source remains after a newline.
## @details
## Whitespace, blank lines, and comments are ignored.  This prevents the final
## source newline from manufacturing a semicolon when EOF already terminates the
## final statement or rule.  The function reads the global buffered `source` but
## does not mutate transformation state.
## @param pos First source position to inspect.
## @param length_source Total source length.
## @local i Current source position.
## @local ch Current source character.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns A numeric truth value.
function remaining_source_has_token(pos, length_source,    i, ch) {
  i = pos
  while (i <= length_source) {
    ch = substr(source, i, 1)
    if (is_horizontal_space(ch) || ch == "\n") {
      i++
      continue
    }
    if (ch == "#") {
      while (i <= length_source && substr(source, i, 1) != "\n") {
        i++
      }
      continue
    }
    return 1
  }
  return 0
}

## @fn reset_transform_context()
## @brief Resets structural state before one complete transformation.
## @details
## Scalar state and scratch stacks are returned to their initial values so one
## complete transformation begins without residue from an earlier invocation.
## The arrays are global because portable AWK does not provide local arrays.
## @local i Scratch array index used while clearing global context arrays.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns No meaningful value; callers use the function for its side effects.
function reset_transform_context(    i) {
  expect_operand = 1
  line_has_content = 0
  pending_space = 0
  last_normal_char = ""
  newline_optional_after = 0
  newline_space_after = 0
  paren_depth = 0
  brace_depth = 0
  do_count = 0
  pending_control = ""
  function_state = 0

  for (i in paren_kind) {
    delete paren_kind[i]
  }
  for (i in do_depth) {
    delete do_depth[i]
  }
}

## @fn note_identifier_context(token)
## @brief Updates control and newline context after an identifier or keyword.
## @details
## `do` statements are tracked at their current brace depth.  A `while` token at
## that same depth following a completed statement is classified as the trailer of
## the innermost pending `do`; other `while` tokens introduce ordinary loops.
## The function also tracks function-definition headers and whether `do` or
## `else` permits a following physical newline to disappear.
## @param token Identifier token.
## @local trailer Whether `while` closes a pending `do` statement.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns No meaningful value; callers use the function for its side effects.
function note_identifier_context(token,    trailer) {
  trailer = 0
  if (token == "while" && do_count > 0 &&
      do_depth[do_count] == brace_depth &&
      (last_normal_char == ";" || last_normal_char == "}")) {
    trailer = 1
    delete do_depth[do_count]
    do_count--
  }

  newline_optional_after = (token == "do" || token == "else")
  newline_space_after = newline_optional_after

  if (token == "do") {
    do_count++
    do_depth[do_count] = brace_depth
  }

  if (token == "if" || token == "for") {
    pending_control = token
  } else if (token == "while") {
    if (trailer) {
      pending_control = "do_while"
    } else {
      pending_control = "while"
    }
  }

  if (token == "function") {
    function_state = 1
  } else if (function_state == 1) {
    function_state = 2
  }
}

## @fn open_paren_context()
## @brief Pushes the grammatical role of one opening parenthesis.
## @details
## A parenthesis immediately associated with `if`, `for`, ordinary `while`, a
## `do ... while` trailer, or a function definition is tagged so the matching
## close can decide whether a subsequent newline is grammar-optional.  Other
## parentheses are recorded as ordinary expression grouping.
## @local kind Grammatical role assigned to the opening parenthesis.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns No meaningful value; callers use the function for its side effects.
function open_paren_context(    kind) {
  kind = "normal"
  if (pending_control != "") {
    kind = pending_control
    pending_control = ""
  } else if (function_state == 2) {
    kind = "function"
    function_state = 0
  }

  paren_depth++
  paren_kind[paren_depth] = kind
  expect_operand = 1
  newline_optional_after = 0
  newline_space_after = 0
}

## @fn close_paren_context()
## @brief Pops one parenthesis and records whether a following newline is optional.
## @details
## Closing `if`, `for`, ordinary `while`, and function-definition headers may be
## followed by the body on the next physical line.  The closing parenthesis of a
## `do ... while` trailer instead completes the statement and is not optional.
## @local kind Grammatical role of the closing parenthesis.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns No meaningful value; callers use the function for its side effects.
function close_paren_context(    kind) {
  kind = "normal"
  if (paren_depth > 0) {
    kind = paren_kind[paren_depth]
    delete paren_kind[paren_depth]
    paren_depth--
  }

  expect_operand = 0
  newline_optional_after = (kind == "if" || kind == "for" ||
                            kind == "while" || kind == "function")
  newline_space_after = 0
}

## @fn note_punctuation_context(ch)
## @brief Updates expression and newline context after one punctuation token.
## @details
## Parentheses delegate to the structural stack helpers.  Braces maintain action
## depth, and comma, semicolon, and opening brace establish positions where a
## following physical newline can be discarded.  Other punctuation updates only
## the operand expectation used by slash classification.
## @param ch One-character punctuation token.
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
## @returns No meaningful value; callers use the function for its side effects.
function note_punctuation_context(ch) {
  newline_optional_after = 0
  newline_space_after = 0

  if (ch == "(") {
    open_paren_context()
  } else if (ch == ")") {
    close_paren_context()
  } else if (ch == "{") {
    brace_depth++
    expect_operand = 1
    newline_optional_after = 1
  } else if (ch == "}") {
    if (brace_depth > 0) {
      brace_depth--
    }
    expect_operand = 0
  } else if (ch == ",") {
    expect_operand = 1
    newline_optional_after = 1
  } else if (ch == ";") {
    expect_operand = 1
    newline_optional_after = 1
  } else if (ch == "]") {
    expect_operand = 0
  } else if (ch == "[") {
    expect_operand = 1
  } else if (ch == "?" || ch == ":" || ch == "=" || ch == "+" ||
             ch == "-" || ch == "*" || ch == "%" || ch == "^" ||
             ch == "~" || ch == "!" || ch == "<" || ch == ">" ||
             ch == "$" || ch == "|") {
    expect_operand = 1
  } else {
    expect_operand = 0
  }
}
