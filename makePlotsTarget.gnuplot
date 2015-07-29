#!/usr/bin/gnuplot
set term postscript eps enhanced color size 3.5,2.62 linewidth 2 

set out "target1.eps"
set key off
set logscale y 2
set yrange [0.75 : 13]
set xrange [1:25]
set xlabel "Time index"
set ylabel "Prosumption"

plot for [col=2:19] 'target1.csv' using 1:col w l

