#!/bin/bash
echo "querying $INFLUXDB_DB"
curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "db="$INFLUXDB_DB --data-urlencode "q=DROP SERIES FROM wordmetric"
curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "db="$INFLUXDB_DB --data-urlencode "q=DROP MEASUREMENT wordmetric"

