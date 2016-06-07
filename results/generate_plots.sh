#!/bin/bash
if [ "$ext" = emf ]
then
    gnuplot -e "ext='emf'" makePlots.gpi
    gnuplot -e "ext='emf'" makePlots_deliv.gpi
else
    ./makePlots.gpi
    ./makePlots_deliv.gpi
    sed -i.bak 's#^/LC5 {1 1 0} def$#/LC5 {1 0.6 0} def#' *.eps
fi

