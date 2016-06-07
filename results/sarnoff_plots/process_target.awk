#!/usr/bin/awk -f
BEGIN {
  FS=","
  OFS=","
}
function abs(v) {return v < 0 ? -v : v}

{
  e_f[$1][int(NR/FNR)] = $4 - $2
  e_nf[$1][int(NR/FNR)] = $6 - $2
}
END {
  for(i=0;i<10;i++) {
#    printf "%s\t", i
    mae_f = 0
    mae_nf = 0
    c = 0
    for (j in e_f[i]) {
#      printf "%s\t", e_f[i][j]
       mae_f += abs(e_f[i][j])
       mae_nf += abs(e_nf[i][j])
       c ++
    }
    mae_f /= c
    mae_nf /= c
    for (j in e_f[i]) {
      st_f += (abs(e_f[i][j]) - mae_f)^2
      st_nf += (abs(e_nf[i][j]) - mae_nf)^2
    }
    st_f = sqrt(st_f / (c - 1))
    st_nf = sqrt(st_nf / (c - 1))


    print i, mae_f, st_f, mae_nf, st_nf
  }
}

