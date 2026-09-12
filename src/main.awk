## @file src/main.awk
## @brief Input buffering and final publication for AWK Minifier.

## @rule collect_source
## @brief Buffers each physical input record and its newline.
## @details
## The complete source is retained so lexical validation can finish before any
## transformed bytes are exposed on STDOUT.
{
  source = source $0 "\n"
}

## @rule finish
## @brief Transforms the buffered source and publishes it only on success.
## @details
## A failed transformation writes one diagnostic to STDERR and exits nonzero.
## Successful transformations flush all buffered output chunks in order.
END {
  transform_source()

  if (failed) {
    printf "awk-minifier: %s\n", failure_message > "/dev/stderr"
    exit 2
  }

  for (output_index = 1; output_index <= output_count; output_index++) {
    printf "%s", output_chunk[output_index]
  }
}
