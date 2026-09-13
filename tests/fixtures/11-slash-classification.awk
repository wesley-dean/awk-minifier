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
