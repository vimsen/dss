#!/usr/bin/awk -f
BEGIN {
  FS = "\t"
  OFS = "\t"
}
{
  h[FNR] = $1
  maxNF = NF > maxNF ? NF : maxNF
  maxFNR = FNR > maxFNR ? FNR : maxFNR
  for (i = 2; i <= NF; i++) {
    a[FNR, i] += $i
    count[FNR, i] ++
  }
}
END {
  for  (j = 1; j <= maxFNR; j++) {
    printf "%s\t", h[j]
    for (i = 2; i <= NF; i++) {
      printf "%s%s", a[j, i] / count[j, i], (i == NF ? ORS : OFS)
    }
  }

}
