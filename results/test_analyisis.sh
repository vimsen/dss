#!/bin/bash
for file in test_{{pos,neg}_{error,cons},genetic,adaptive}_[0-9]_0{"",_before,_after}.csv
do
  ./sum.awk "$file" > "${file%.*}_sum.csv"
  ./avg.awk "$file" > "${file%.*}_avg.csv"
done

for prefix in {{pos,neg}_{error,cons},genetic,adaptive}
do
  for suffix in {"",_before,_after}_{sum,avg}
  do
    awk -v OFS='\t' '
         FNR > 1 {
           s[FNR] += $2
           c[FNR]++
           m = ( m > FNR ? m : FNR )
         }
         END{
           for(i=2;i<=m;i++)
             print i - 2, s[i] / c[i]
         }' test_"$prefix"_?_0"$suffix".csv > test_"$prefix$suffix".csv
    

  done
  paste test_"$prefix"_before_sum.csv test_"$prefix"_after_sum.csv | awk -v OFS='\t' '{print $1, ($2-$4)/$2*100}' > test_"$prefix"_tot_impr.csv
  for suffix in {"",_before,_after}
  do
    for run in {0..9}
    do
      ./extract_first_week.awk kappa_?_"$prefix"_"$run"_0"$suffix".csv > "$prefix"_k_"$run$suffix".csv
    ./sum.awk "$prefix"_k_"$run$suffix".csv > "$prefix"_k_"$run$suffix"_sum.csv
    ./avg.awk "$prefix"_k_"$run$suffix".csv > "$prefix"_k_"$run$suffix"_avg.csv
    done
    ./average_columns_nohead.awk "$prefix"_k_?"$suffix"_sum.csv > "$prefix"_k"$suffix"_sum.csv
    ./average_columns_nohead.awk "$prefix"_k_?"$suffix"_avg.csv > "$prefix"_k"$suffix"_avg.csv
  done

  paste "$prefix"_k_before_sum.csv "$prefix"_k_after_sum.csv | awk -v OFS='\t' '{print $1, ($2-$4)/$2*100}' > "$prefix"_k_tot_impr.csv
done

for proto in smart static
do
  ./standard_error.awk "$proto"_? | sort -n > "$proto"_se
done
