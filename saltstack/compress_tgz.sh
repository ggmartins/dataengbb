#!/bin/bash

STARTTIME=$(date +%s)
s=/srv/salt/data

for d in $s/*/ ; do
if ls $d/*.out.tar.gz 1> /dev/null 2>&1; then
    dev=$(basename $d)
    date=$(date +%Y%m%d)
    t="$d"$date
    
    cd $d
    mkdir -p $date
    mv *.out.tar.gz $date
    tar cvzf $date-$dev.tgz $date
    rm -Rf $date/
    echo "created $date-$dev.tgz"
    cd -
else
    echo "files not found"
fi
done
ENDTIME=$(date +%s)
echo "elapsed_time: $(($ENDTIME - $STARTTIME))"
