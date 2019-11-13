#!/bin/bash

for i in $(cat out3);do

s=$(find . -name $i 2>/dev/null)
cp $s $s.1
done

