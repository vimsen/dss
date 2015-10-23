#!/bin/bash
./makePlots
./makePlots_deliv
sed -i.bak 's#^/LC5 {1 1 0} def$#/LC5 {1 0.6 0} def#' *.eps

