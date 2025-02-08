#!/bin/bash

#step 1: compile the source to `code' binary using vasmm

vasmm68k_mot -noesc -align -opt-speed -opt-allbra -rangewarnings -Fbin -o code $1					

#step 2: the code needs to be autoladed by the ql, this is done by making a "boot" file
# boot file is autoloaded on QL and its contents are automatically executed


# prepare: determine the filesize of the code from step 1
# this is done to let QDOS allocate enough emmory to load the file
FILENAME=code
FILESIZE=$(stat -f%z "$FILENAME")

# these are the statements that make into the boot file
# print outputs to display on QL
echo "5 print \"Allocating...\"" > boot
# RESPR reserves a memory amount an assigns this locaiton to variable a in QL basic
echo "10 a=RESPR($FILESIZE)" >> boot
# print
echo "11 print \"Microdrive spinning up...\"" >> boot
# LBYTES is the command ot load a filename to a memory location, here we load MICRODIVE_ CODE (code the binary we made)
# and its loaded into memory location a, that we just allocated space to
echo "15 LBYTES \"mdv1_code\",a" >> boot
# print
echo "16 print \"Running...\"" >> boot
# now we can run the binary we loaded
echo "20 CALL a" >> boot

# this is additional scripting to copy the "boot" and "code" files we made int his batch to a location where 
# the Qemulator resides
cp boot ~/atari/code/ql/
cp code ~/atari/code/ql/

