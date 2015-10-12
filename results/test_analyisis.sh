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
done
