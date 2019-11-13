#!/bin/bash

sudo salt --out json --hide-timeout --out-file=reportstatus.log.salt.json '*' cmd.run "ping -b 192.168.143.255 -c 2 2>%1 >/dev/null; cat /etc/bismark/ID; arp -n | grep 192.168.143 | grep -v incomplete | grep -v '192.168.143.1 ' | wc -l; ps -auxwww | grep [t]raffic" > reportstatus.log 2>&1
source .reportstatus.env
./reportstatus.py >>reportstatus.log 2>&1

