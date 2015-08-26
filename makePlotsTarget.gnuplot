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

set out "target2_1.eps"
set yrange [*:*]
plot for [col=2:10] 'target2.csv' using 1:col w l, \
     for [col=11:19] 'target2.csv' using 1:col w p


set out "target2_2.eps"
set ylabel "Prosumption (negative)"
set yrange [*:512] reverse
plot for [col=2:10] 'target2.csv' using 1:(-column(col)) w l, \
     for [col=11:19] 'target2.csv' using 1:(-column(col)) w p

set out "target2_stats.eps"
set ylabel "percentage (%)"
set key autotitle columnhead

unset yrange
unset logscale
set yrange [60:110]
set xrange [*:*]
set y2label 'Mean Square Error'
set y2range [-0.02: 0.2]
set y2tics 0.05
plot for [col=2:3] 'target2_stats.csv' using 1:(100 * column(col)) w lp, \
     'target2_stats.csv' using 1:4 axes x1y2 w lp
