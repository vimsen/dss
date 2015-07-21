#!/usr/bin/awk -f
BEGIN {
  OFS="\t"
}
$1 == 0 {
  $1 = ARGIND; print
}
