#!/usr/bin/awk -f
BEGIN { value = "# literal";if (value ~ /#[a-z ]+/) { print value };ratio = 10 / 2;}