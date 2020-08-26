#!/bin/bash

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,latitude=41.795,longitude=-87.60,lat=41.795,lon=-87.60,country=US,id=100 metric=100 '$TS
