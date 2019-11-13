#!/bin/bash

STARTTIME=$(date +%s)
if [ -z "$1" ]; then
  echo "usage: $0 <all> | <id>"
  exit 1
fi

origin="/tmp/ta.*"
destination="/srv/salt/data/"

if [ "$1" == "all" ]; then
 for i in $(sudo salt-run manage.up | awk '{print $2}'); do
 echo "For $i, processing ... "
  R=$(sudo salt $i cmd.run 'ls '"$origin" | awk '{if(NR>1)print}')
  if echo $R | grep -E "cannot|did not" > /dev/null ;then
    echo "$i Down"
  else
    echo -e "OK Processing\n$R"
    for j in $R;do
     mkdir -p $destination/$i/
     echo "sudo salt $i cp.push $j remove_source=True"
     sudo salt $i cp.push $j remove_source=True
     cp /var/cache/salt/master/minions/$i/files/$j $destination/$i/
     #no powers to rm that, ask j
     #sudo rm -f /var/cache/salt/master/minions/$i/files/$j
    done 
  fi
done
else
  echo "For $1, processing ... "
  R=$(sudo salt $1 cmd.run 'ls '"$origin" | awk '{if(NR>1)print}')
  if echo $R | grep -E "cannot|did not" > /dev/null ;then
    echo "$1 Down"
  else
    echo -e "OK Processing\n$R"
    for j in $R;do
     mkdir -p $destination/$1/
     sudo salt $1 cp.push $j remove_source=True
     cp /var/cache/salt/master/minions/$1/files/$j $destination/$1/
     #no powers to rm that, ask josko
     #sudo rm -f /var/cache/salt/master/minions/$1/files/$j
    done
  fi
fi
ENDTIME=$(date +%s)
echo "elapsed_time: $(($ENDTIME - $STARTTIME))"
