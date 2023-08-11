#!/usr/bin/bash


outfile=$1
shift
echo $@
echo Adding $# lines to $outfile

for line in $@
do
    echo $line >> $outfile 
done

echo SCRIPT DONE