#!/bin/sh
php psgtoym13.php $1 > $1.s
../build/68bin $1.s
php tool.php $1.s.bin $1.ym3
miny small $1.ym3 $1.ymp
