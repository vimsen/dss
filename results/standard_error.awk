#!/usr/bin/gawk -f 
BEGIN { FS=OFS="\t" }
FNR > 1 {
    time[$1][f]+=$2
    fit[$1][f]+=$3  
}
ENDFILE {f++}
END {
  for (g in time) {
    sum = 0
    count = 0
    sum_time = 0
    sum_fit = 0
    sum2_time = 0
    sum2_fit = 0
    for (v in time[g]) {
      sum_time += time[g][v]
      sum_fit += fit[g][v]
      count ++
    }
    avg_time = sum_time / count
    avg_fit = sum_fit / count
    for (v in time[g]) {
      sum2_time += (time[g][v] - avg_time)^2
      sum2_fit += (fit[g][v] - avg_fit)^2
    }
    s_time = sqrt(sum2_time) / (count - 1)
    s_fit = sqrt(sum2_fit) / (count - 1)

    se_time = s_time / sqrt(count)
    se_fit = s_fit / sqrt(count)

    print g, avg_time, avg_time - s_time, avg_time + s_time,
             avg_fit, avg_fit - s_fit, avg_fit + s_fit
  }
}
