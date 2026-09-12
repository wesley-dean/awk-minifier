## @file src/diagnostics.awk
## @brief Diagnostic state and failure reporting for AWK Minifier.

## @fn fail(message)
## @brief Records the first transformation failure.
## @details
## A failure prevents buffered output from being published.  Only the first
## diagnostic is retained so one malformed lexical construct does not produce a
## cascade of misleading follow-on messages.
##
## @param message Human-readable diagnostic text.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written immediately; the diagnostic is emitted by `finish`.
##
## @returns Nothing.
function fail(message) {
  if (!failed) {
    failed = 1
    failure_message = message
  }
}
