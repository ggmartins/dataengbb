#!/bin/bash

id=$(cat /etc/salt/minion_id)
for o in `ls /tmp/nm/nm-exp-active-netrics/upload/pending/default/out/`; do
curl -T $o ftp://$NMFTPUSER:$NMFTPPASS@$NMSRV:$NMFTPPORT/$id/$o
done
for p in `ls /tmp/nm/nm-exp-active-netrics/upload/pending/default/pkl/`; do
curl -T $p ftp://$NMFTPUSER:$NMFTPPASS@#NMSRV:$NMFTPPORT/$id/$p
done
