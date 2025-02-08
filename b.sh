#!/bin/bash

# assemble part, and pack it up
cd splash && ../build/ql-build.sh splash.s && salvador code code.zx0 && cd ..
if [ $? -eq 1 ]; then
        exit 1
fi

# assemble part, and pack it up
cd reveal && ../build/ql-build.sh reveal.s && salvador code code.zx0 && cd ..
if [ $? -eq 1 ]; then
        exit 1
fi


# assemble part, and pack it up
cd bobs && ../build/ql-build.sh bobs.s && salvador code code.zx0 && cd ..
if [ $? -eq 1 ]; then
        exit 1
fi

# assemble main with all included above parts
build/ql-build-relative.sh main.s

# use mdvtool to generate a mdv
mdvtool create name qlsys import boot import code write qlsys.mdv

# copy mdv file to SDCARD
cp ./qlsys.mdv /Volumes/QL

# copy produced code to qemulator location for cycle time
cp boot ../ql/
cp code ../ql/
