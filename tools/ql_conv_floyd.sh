#!/bin/bash
if [ $# -lt 2 ];
   then
   printf "Usage: cnv_floyd.sh file_in file_out\n"#
   exit 0
   fi

convert $1 +depth -dither FloydSteinberg -remap ~/bin/data/pal.bmp $2
