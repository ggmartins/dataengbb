#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "usage: ./apply-to-list <list name>"
    exit 1
fi




while read line
do
  Arch=$(echo $line | awk -F' ' '{print $1}')
  Name=$(echo $line | awk -F' ' '{print $2}')
 
  target=$(echo "ta_$Arch""_stop") 
  echo "Applying Stop to $Name with $target ..."
  sudo salt $Name state.apply $target

  target=$(echo "ta_$Arch""_base") 
  echo "Applying Base to $Name with $target ..."
  sudo salt $Name state.apply $target
 
  echo "Applying Spec for $Name"
  cp ta_spec/init.spec ta_spec/init.sls
  sed -i 's/test1/'$Name'/g' ta_spec/init.sls 
  sudo salt $Name state.apply ta_spec 

  target1=$(echo "ta_$Arch""_start") 
  echo "Applying Run to $Name with $target1"
  sudo salt $Name state.apply $target1
done < "$1"
