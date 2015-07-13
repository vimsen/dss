#!/usr/bin/awk -f
BEGIN {
  FS = "\t"
  OFS = "\t"
}
FNR > 1 {
  h[FNR] = $1
  for (i = 2; i <= NF; i++) {
    a[FNR, i] += $i
    count[FNR, i] ++
  }
}
END {
  printf "Week\t"
  for (i = 0; i<= NF - 1; i++)
    printf "Adaptive %s%s", i, (i == NF - 1 ? ORS : OFS)
  for  (j = 2; j <= FNR; j++) {
    printf "%s\t", h[j]
    for (i = 2; i <= NF; i++) {
      printf "%s%s", a[j, i] / count[j, i], (i == NF ? ORS : OFS)
    }
  }

}
