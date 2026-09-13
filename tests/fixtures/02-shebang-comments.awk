#!/usr/bin/awk -f
# file comment
BEGIN {   value = "# literal"   # inline comment
  if (value ~ /#[a-z ]+/) { print value } # tail
  ratio = 10 / 2
}
