#!/bin/bash
for i in {10..300..10}
do
  ./process_target.awk plot_data_10_"$i"_*.csv > target_errors_"$i".csv
done
