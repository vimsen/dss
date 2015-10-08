#!/bin/bash

for file in test_{{pos,neg}_{error,cons},genetic}_[0-9]_0_before.csv
do
  ./sum.awk "$file" > "${file%.*}_sum.csv"
done

for file in test_{{pos,neg}_{error,cons},genetic}_[0-9]_0_after.csv
do
  ./sum.awk "$file" > "${file%.*}_sum.csv"
done

for prefix in {{pos,neg}_{error,cons},genetic}
do
  for suffix in {before,after}
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
         }' test_"$prefix"_?_0_"$suffix"_sum.csv > test_"$prefix"_"$suffix"_sum.csv
  done
done
