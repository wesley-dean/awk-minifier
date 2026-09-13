#!/bin/sh
set -eu

AWK_BIN=${AWK_BIN:-awk}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=${TMPDIR:-/tmp}/awk-minifier-tests.$$
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$TMP"

MODULAR="$AWK_BIN -f $ROOT/src/diagnostics.awk -f $ROOT/src/output.awk -f $ROOT/src/context.awk -f $ROOT/src/lexer.awk -f $ROOT/src/transform.awk -f $ROOT/src/main.awk"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

announce() {
  printf 'TEST: %s\n' "$1"
}

announce_subtest() {
  printf '  - %s\n' "$1"
}

run_modular() {
  # shellcheck disable=SC2086
  $MODULAR
}

newline_count() {
  tr -cd '\n' <"$1" | wc -c | tr -d '[:space:]'
}

printf 'AWK Minifier test suite (%s)\n' "$AWK_BIN"

announce 'basic transformation and shebang physical-line invariant'
cat >"$TMP/basic.awk" <<'CASE'
#!/usr/bin/awk -f
# file comment
BEGIN {   value = "# literal"   # inline comment
  if (value ~ /#[a-z ]+/) { print value } # tail
  ratio = 10 / 2
}
CASE
printf '%s\n%s' \
  '#!/usr/bin/awk -f' \
  'BEGIN { value = "# literal";if (value ~ /#[a-z ]+/) { print value };ratio = 10 / 2;}' \
  >"$TMP/basic.expected"
run_modular <"$TMP/basic.awk" >"$TMP/basic.actual"
cmp -s "$TMP/basic.expected" "$TMP/basic.actual" || {
  diff -u "$TMP/basic.expected" "$TMP/basic.actual" >&2 || true
  fail 'basic golden transformation'
}
[ "$(newline_count "$TMP/basic.actual")" -eq 1 ] || fail 'shebang output physical-line invariant'

announce 'idempotence of already-minified source'
run_modular <"$TMP/basic.actual" >"$TMP/basic.twice"
cmp -s "$TMP/basic.actual" "$TMP/basic.twice" || fail 'idempotence'

announce 'semantic equivalence and zero-newline output without shebang'
cat >"$TMP/semantic.awk" <<'CASE'
BEGIN { FS="," }
$1 ~ /a#[0-9]+/ { total += $2 / 2 }
END { print total }
CASE
printf 'a#1,8\na#2,4\nno,100\n' >"$TMP/data"
run_modular <"$TMP/semantic.awk" >"$TMP/semantic.min.awk"
[ "$(newline_count "$TMP/semantic.min.awk")" -eq 0 ] || fail 'non-shebang output retained physical newline'
"$AWK_BIN" -f "$TMP/semantic.awk" "$TMP/data" >"$TMP/original.out"
"$AWK_BIN" -f "$TMP/semantic.min.awk" "$TMP/data" >"$TMP/minified.out"
cmp -s "$TMP/original.out" "$TMP/minified.out" || fail 'semantic equivalence'

announce 'portable explicit backslash-newline continuation between tokens'
cat >"$TMP/continuation.awk" <<'CASE'
BEGIN {
  value = 1 + \
    2 # comment
  text = "a" \
    "b"
  print value, text
}
CASE
run_modular <"$TMP/continuation.awk" >"$TMP/continuation.min.awk"
"$AWK_BIN" -f "$TMP/continuation.awk" </dev/null >"$TMP/continuation.original.out"
"$AWK_BIN" -f "$TMP/continuation.min.awk" </dev/null >"$TMP/continuation.out"
cmp -s "$TMP/continuation.original.out" "$TMP/continuation.out" || fail 'continued expression'
grep -Fq 'value = 1 + 2' "$TMP/continuation.min.awk" || fail 'explicit continuation removal'

announce 'reject non-portable backslash-newline inside string literal'
cat >"$TMP/nonportable-string-continuation.awk" <<'CASE'
BEGIN {
  text = "a\
b"
  print text
}
CASE
if run_modular <"$TMP/nonportable-string-continuation.awk" \
    >"$TMP/nonportable-string.stdout" 2>"$TMP/nonportable-string.stderr"; then
  fail 'backslash-newline inside string should fail portability check'
fi
[ ! -s "$TMP/nonportable-string.stdout" ] || fail 'non-portable string continuation published partial stdout'
grep -Fq 'backslash-newline inside string literal is not portable' \
  "$TMP/nonportable-string.stderr" || fail 'missing non-portable string continuation diagnostic'

announce 'reject non-portable backslash-newline inside regexp literal'
cat >"$TMP/nonportable-regexp-continuation.awk" <<'CASE'
BEGIN {
  if ("ab" ~ /a\
b/) print "match"
}
CASE
if run_modular <"$TMP/nonportable-regexp-continuation.awk" \
    >"$TMP/nonportable-regexp.stdout" 2>"$TMP/nonportable-regexp.stderr"; then
  fail 'backslash-newline inside regexp should fail portability check'
fi
[ ! -s "$TMP/nonportable-regexp.stdout" ] || fail 'non-portable regexp continuation published partial stdout'
grep -Fq 'backslash-newline inside regexp literal is not portable' \
  "$TMP/nonportable-regexp.stderr" || fail 'missing non-portable regexp continuation diagnostic'

announce 'control-flow newline semantics'
cat >"$TMP/control.awk" <<'CASE'
BEGIN {
  x = 0
  if (1) # condition comment
    x++
  else # else comment
    x += 100
  while (x < 3)
    x++
  for (i = 0; i < 2; i++)
    x++
  do # simple do body
    x++
  while (x < 6)
  do {
    while (x < 7)
      x++
    x++
  } while (x < 8)
  if (x == 8) {
    if (1) {
      x++
    } else {
      x += 1000
    }
  }
  print x
}
CASE
run_modular <"$TMP/control.awk" >"$TMP/control.min.awk"
"$AWK_BIN" -f "$TMP/control.awk" </dev/null >"$TMP/control.original.out"
"$AWK_BIN" -f "$TMP/control.min.awk" </dev/null >"$TMP/control.minified.out"
cmp -s "$TMP/control.original.out" "$TMP/control.minified.out" || fail 'control-flow newline semantics'
[ "$(newline_count "$TMP/control.min.awk")" -eq 0 ] || fail 'control-flow output retained newline'
grep -Fq 'if (1)x++;else x += 100' "$TMP/control.min.awk" || fail 'if/else header joining'
grep -Fq 'while (x < 3)x++' "$TMP/control.min.awk" || fail 'while header joining'
grep -Fq 'for (i = 0; i < 2; i++)x++' "$TMP/control.min.awk" || fail 'for header joining'
grep -Fq 'do x++;while (x < 6)' "$TMP/control.min.awk" || fail 'simple do/while separation'

announce 'function-definition header newline semantics'
cat >"$TMP/function.awk" <<'CASE'
function twice(value)
{
  return value * 2
}
BEGIN {
  print twice(4)
}
CASE
run_modular <"$TMP/function.awk" >"$TMP/function.min.awk"
"$AWK_BIN" -f "$TMP/function.awk" </dev/null >"$TMP/function.original.out"
"$AWK_BIN" -f "$TMP/function.min.awk" </dev/null >"$TMP/function.minified.out"
cmp -s "$TMP/function.original.out" "$TMP/function.minified.out" || fail 'function header newline semantics'
grep -Fq 'function twice(value){' "$TMP/function.min.awk" || fail 'function header joining'

announce 'grammar-optional newlines after logical operators and comma'
cat >"$TMP/optional.awk" <<'CASE'
BEGIN {
  truth = (1 &&
           1) ||
          0
  print "left",
        "right", truth
}
CASE
run_modular <"$TMP/optional.awk" >"$TMP/optional.min.awk"
"$AWK_BIN" -f "$TMP/optional.awk" </dev/null >"$TMP/optional.original.out"
"$AWK_BIN" -f "$TMP/optional.min.awk" </dev/null >"$TMP/optional.minified.out"
cmp -s "$TMP/optional.original.out" "$TMP/optional.minified.out" || fail 'grammar-optional newline semantics'
[ "$(newline_count "$TMP/optional.min.awk")" -eq 0 ] || fail 'grammar-optional output retained newline'

announce 'unterminated string failure and no partial output'
printf 'BEGIN { print "unterminated\n' >"$TMP/bad-string.awk"
if run_modular <"$TMP/bad-string.awk" >"$TMP/bad.stdout" 2>"$TMP/bad.stderr"; then
  fail 'unterminated string should fail'
fi
[ ! -s "$TMP/bad.stdout" ] || fail 'malformed input published partial stdout'
grep -q 'unterminated string literal' "$TMP/bad.stderr" || fail 'missing malformed-string diagnostic'

announce 'unterminated regexp failure and no partial output'
printf '/unterminated { print }\n' >"$TMP/bad-regexp.awk"
if run_modular <"$TMP/bad-regexp.awk" >"$TMP/bad-regexp.stdout" 2>"$TMP/bad-regexp.stderr"; then
  fail 'unterminated regexp should fail'
fi
[ ! -s "$TMP/bad-regexp.stdout" ] || fail 'malformed regexp published partial stdout'
grep -q 'unterminated regexp literal' "$TMP/bad-regexp.stderr" || fail 'missing malformed-regexp diagnostic'

announce 'assembled release artifact behavior'
for artifact in "$ROOT/dist/awk-minifier.dev.awk" "$ROOT/dist/awk-minifier.awk" "$ROOT/dist/awk-minifier.min.awk"; do
  [ -f "$artifact" ] || continue
  announce_subtest "$(basename "$artifact")"
  "$AWK_BIN" -f "$artifact" <"$TMP/basic.awk" >"$TMP/artifact.out"
  cmp -s "$TMP/basic.expected" "$TMP/artifact.out" || fail "artifact behavior: $(basename "$artifact")"
done

announce 'regexp, division, chained division, and division-assignment classification'
cat >"$TMP/slashes.awk" <<'CASE'
BEGIN {
  a = 24
  b = 6
  c = 2
  a /= 2
  print a / b / c
  text = "a/b#c"
  if (text ~ /a\/b#c/) print text
  if (text !~ /nomatch/) print "ok"
}
CASE
run_modular <"$TMP/slashes.awk" >"$TMP/slashes.min.awk"
"$AWK_BIN" -f "$TMP/slashes.awk" </dev/null >"$TMP/slashes.original.out"
"$AWK_BIN" -f "$TMP/slashes.min.awk" </dev/null >"$TMP/slashes.minified.out"
cmp -s "$TMP/slashes.original.out" "$TMP/slashes.minified.out" || fail 'regexp/division classification'
grep -Fq 'a /= 2' "$TMP/slashes.min.awk" || fail 'division assignment preservation'
grep -Fq '/a\/b#c/' "$TMP/slashes.min.awk" || fail 'escaped regexp and hash preservation'

announce 'top-level rule separation after newline elimination'
cat >"$TMP/rule.awk" <<'CASE'
/foo#bar/ { print $1 }
/bar/
END { print "done" }
CASE
printf 'foo#bar yes\nbar no\nother no\n' >"$TMP/rule.data"
run_modular <"$TMP/rule.awk" >"$TMP/rule.min.awk"
"$AWK_BIN" -f "$TMP/rule.awk" "$TMP/rule.data" >"$TMP/rule.original.out"
"$AWK_BIN" -f "$TMP/rule.min.awk" "$TMP/rule.data" >"$TMP/rule.minified.out"
cmp -s "$TMP/rule.original.out" "$TMP/rule.minified.out" || fail 'top-level rule separation'
grep -Fq '};/bar/;END' "$TMP/rule.min.awk" || fail 'top-level semicolon separation'

announce 'escaped quotes and hash characters inside strings'
cat >"$TMP/hash-string.awk" <<'CASE'
BEGIN {
  print "quoted # text with \"escape\""
}
CASE
run_modular <"$TMP/hash-string.awk" >"$TMP/hash-string.min.awk"
"$AWK_BIN" -f "$TMP/hash-string.awk" </dev/null >"$TMP/hash-string.original.out"
"$AWK_BIN" -f "$TMP/hash-string.min.awk" </dev/null >"$TMP/hash-string.minified.out"
cmp -s "$TMP/hash-string.original.out" "$TMP/hash-string.minified.out" || fail 'escaped string preservation'

announce 'candidate self-minification to shebang plus one program line'
if [ -f "$ROOT/dist/awk-minifier.dev.awk" ]; then
  run_modular <"$ROOT/dist/awk-minifier.dev.awk" >"$TMP/self.min.awk"
  [ "$(newline_count "$TMP/self.min.awk")" -eq 1 ] || fail 'candidate self-minification did not collapse to shebang plus one program line'
  "$AWK_BIN" -f "$TMP/self.min.awk" </dev/null >/dev/null || fail 'candidate self-minified artifact is not executable AWK'
else
  announce_subtest 'skipped: dist/awk-minifier.dev.awk is not present'
fi

printf 'PASS: AWK Minifier tests (%s)\n' "$AWK_BIN"
