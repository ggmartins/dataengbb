#!/bin/bash
#echo "querying $INFLUXDB_DB"
curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "q=SELECT value FROM $INFLUXDB_DB.rp.testmetric"
