#!/bin/bash

for k in {1..9}
do
   echo "$k: " result_adaptive_k_$k_?.csv 
  ./average_columns.awk result_adaptive_k_${k}_?_after.csv > result_adaptive_k_${k}_after_avg.csv
done
