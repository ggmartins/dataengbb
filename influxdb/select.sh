#!/bin/bash
#echo "querying $INFLUXDB_DB"
curl -XPOST -G http://localhost:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "q=SELECT * FROM $INFLUXDB_DB.rp.testmetric"
