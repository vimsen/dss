#!/bin/bash

./generate_average_all.sh

./avg.awk result_genetic_k_5_0.csv > genetic_results2_avg.csv
./avg.awk result_spectral_k_5_0.csv > spectral_results_avg.csv
./avg.awk result_adaptive_k_5_avg.csv > adaptive_results_avg.csv

./extract_first_week.awk result_genetic_k_?_0.csv > genetic_k.csv
./extract_first_week.awk result_spectral_k_?_0.csv > spectral_k.csv
./extract_first_week.awk result_adaptive_k_?_avg.csv > adaptive_k.csv

./avg.awk genetic_k.csv > genetic_k_avg.csv
./avg.awk spectral_k.csv > spectral_k_avg.csv
./avg.awk adaptive_k.csv > adaptive_k_avg.csv

./generate_average_all_after.sh 
./extract_first_week.awk result_adaptive_k_?_after_avg.csv | ./sum.awk > adaptive_k_sum.csv
./extract_first_week.awk result_genetic_k_?_0_after.csv | ./sum.awk > genetic_k_sum.csv
./extract_first_week.awk result_spectral_k_?_0_after.csv | ./sum.awk > spectral_k_sum.csv

