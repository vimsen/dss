#!/bin/bash

./generate_average_all.sh
./avg.awk result_adaptive_k_5_avg.csv > adaptive_results_avg.csv
./extract_first_week.awk result_adaptive_k_?_avg.csv > adaptive_k.csv
./avg.awk adaptive_k.csv > adaptive_k_avg.csv
