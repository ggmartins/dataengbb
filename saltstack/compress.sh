#!/bin/bash

s=/srv/salt/data

for d in $s/*/ ; do
    dev=$(basename $d)
    date=$(date +%Y%m%d)
    t="$d"$(date +%Y%m%d)
    
   # echo cd 
    echo $d
    mkdir 
    echo "$(basename $t)-$dev.tgz"
done

#cd $s
#for i in $(find $s -type f -mmin -1440 | xargs ls); do
#    echo "--> " $i
#done
#cd -
 
