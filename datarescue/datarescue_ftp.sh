#!/bin/bash

id=$(cat /etc/salt/minion_id)
for o in `ls /tmp/nm/nm-exp-active-netrics/upload/pending/default/out/`; do
curl -T /tmp/nm/nm-exp-active-netrics/upload/pending/default/out/$o ftp://$NMFTPUSER:$NMFTPPASS@$NMSRV:$NMFTPPORT/$id/$o >/tmp/log_datarescure_out.log 2>&1
done
for p in `ls /tmp/nm/nm-exp-active-netrics/upload/pending/default/pkl/`; do
curl -T /tmp/nm/nm-exp-active-netrics/upload/pending/default/pkl/$p ftp://$NMFTPUSER:$NMFTPPASS@$NMSRV:$NMFTPPORT/$id/$p >/tmp/log_datarescure_pkl.log 2>&1
done
