#!/bin/bash

if [ $# -lt 2 ];
   then
   printf "Usage: cnv_ordered.sh file_in file_out\n"#
   exit 0
   fi

convert $1 +depth -ordered-dither o8x8,6 -remap ~/bin/data/pal.bmp $2
