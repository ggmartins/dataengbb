#!/bin/bash

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'testmetric,tag1=tag1value,tag2=tag2value value=0.123 '$TS
