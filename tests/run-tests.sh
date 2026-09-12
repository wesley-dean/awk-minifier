#!/bin/sh
set -eu

AWK_BIN=${AWK_BIN:-awk}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=${TMPDIR:-/tmp}/awk-minifier-tests.$$
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$TMP"

MODULAR="$AWK_BIN -f $ROOT/src/diagnostics.awk -f $ROOT/src/output.awk -f $ROOT/src/lexer.awk -f $ROOT/src/main.awk"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

run_modular() {
  # shellcheck disable=SC2086
  $MODULAR
}

cat >"$TMP/basic.awk" <<'CASE'
#!/usr/bin/awk -f
# file comment
BEGIN {   value = "# literal"   # inline comment
  if (value ~ /#[a-z ]+/) { print value } # tail
  ratio = 10 / 2
}
CASE
cat >"$TMP/basic.expected" <<'CASE'
#!/usr/bin/awk -f

BEGIN { value = "# literal"
if (value ~ /#[a-z ]+/) { print value }
ratio = 10 / 2
}
CASE
run_modular <"$TMP/basic.awk" >"$TMP/basic.actual"
cmp -s "$TMP/basic.expected" "$TMP/basic.actual" || {
  diff -u "$TMP/basic.expected" "$TMP/basic.actual" >&2 || true
  fail 'basic golden transformation'
}

run_modular <"$TMP/basic.actual" >"$TMP/basic.twice"
cmp -s "$TMP/basic.actual" "$TMP/basic.twice" || fail 'idempotence'

cat >"$TMP/semantic.awk" <<'CASE'
BEGIN { FS="," }
$1 ~ /a#[0-9]+/ { total += $2 / 2 }
END { print total }
CASE
printf 'a#1,8\na#2,4\nno,100\n' >"$TMP/data"
run_modular <"$TMP/semantic.awk" >"$TMP/semantic.min.awk"
"$AWK_BIN" -f "$TMP/semantic.awk" "$TMP/data" >"$TMP/original.out"
"$AWK_BIN" -f "$TMP/semantic.min.awk" "$TMP/data" >"$TMP/minified.out"
cmp -s "$TMP/original.out" "$TMP/minified.out" || fail 'semantic equivalence'

cat >"$TMP/continuation.awk" <<'CASE'
BEGIN {
  value = 1 + \
    2 # comment
  print value
}
CASE
run_modular <"$TMP/continuation.awk" >"$TMP/continuation.min.awk"
"$AWK_BIN" -f "$TMP/continuation.min.awk" </dev/null >"$TMP/continuation.out"
[ "$(cat "$TMP/continuation.out")" = "3" ] || fail 'continued expression'

printf 'BEGIN { print "unterminated\n' >"$TMP/bad-string.awk"
if run_modular <"$TMP/bad-string.awk" >"$TMP/bad.stdout" 2>"$TMP/bad.stderr"; then
  fail 'unterminated string should fail'
fi
[ ! -s "$TMP/bad.stdout" ] || fail 'malformed input published partial stdout'
grep -q 'unterminated string literal' "$TMP/bad.stderr" || fail 'missing malformed-string diagnostic'

printf '/unterminated { print }\n' >"$TMP/bad-regexp.awk"
if run_modular <"$TMP/bad-regexp.awk" >"$TMP/bad-regexp.stdout" 2>"$TMP/bad-regexp.stderr"; then
  fail 'unterminated regexp should fail'
fi
[ ! -s "$TMP/bad-regexp.stdout" ] || fail 'malformed regexp published partial stdout'
grep -q 'unterminated regexp literal' "$TMP/bad-regexp.stderr" || fail 'missing malformed-regexp diagnostic'

for artifact in "$ROOT/dist/awk-minifier.dev.awk" "$ROOT/dist/awk-minifier.awk" "$ROOT/dist/awk-minifier.min.awk"; do
  [ -f "$artifact" ] || continue
  "$AWK_BIN" -f "$artifact" <"$TMP/basic.awk" >"$TMP/artifact.out"
  cmp -s "$TMP/basic.expected" "$TMP/artifact.out" || fail "artifact behavior: $(basename "$artifact")"
done

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

cat >"$TMP/rule.awk" <<'CASE'
/foo#bar/ { print $1 }
CASE
printf 'foo#bar yes\nother no\n' >"$TMP/rule.data"
run_modular <"$TMP/rule.awk" >"$TMP/rule.min.awk"
"$AWK_BIN" -f "$TMP/rule.awk" "$TMP/rule.data" >"$TMP/rule.original.out"
"$AWK_BIN" -f "$TMP/rule.min.awk" "$TMP/rule.data" >"$TMP/rule.minified.out"
cmp -s "$TMP/rule.original.out" "$TMP/rule.minified.out" || fail 'regexp pattern rule preservation'

cat >"$TMP/hash-string.awk" <<'CASE'
BEGIN {
  print "quoted # text with \"escape\""
}
CASE
run_modular <"$TMP/hash-string.awk" >"$TMP/hash-string.min.awk"
"$AWK_BIN" -f "$TMP/hash-string.awk" </dev/null >"$TMP/hash-string.original.out"
"$AWK_BIN" -f "$TMP/hash-string.min.awk" </dev/null >"$TMP/hash-string.minified.out"
cmp -s "$TMP/hash-string.original.out" "$TMP/hash-string.minified.out" || fail 'escaped string preservation'

printf 'PASS: AWK Minifier tests (%s)\n' "$AWK_BIN"
