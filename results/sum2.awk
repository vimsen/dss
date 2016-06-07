#!/usr/bin/awk -f
BEGIN {
  OFS = ","
}
NR > 1{
  s=0
  for (i=1;i<=NF;i++) {
    s+=$i
  }
  print s
}

