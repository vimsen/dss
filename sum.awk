#!/usr/bin/awk -f
BEGIN {
  OFS = "\t"
}
{
  s=0
  for (i=2;i<=NF;i++) {
    s+=$i
  }
  $0 = $1 OFS s
}
1

