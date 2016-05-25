#!/bin/bash

script=~/Dropbox/smart-grid/VIMSEN\ papers/target-clustering/short_term_forecast.m

dir=$(dirname "$script")
matlab -nodisplay -nosplash -nodesktop -r "addpath '$dir'; $(basename "$script" .m)($1,'$2'); rmpath '$dir';exit;"
