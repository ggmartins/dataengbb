#!/bin/bash

#use -k to test localhost
curl -XPOST -G https://localhost:$INFLUXDB_PORT/query -u $INFLUXDB_ADMIN_USER:$INFLUXDB_ADMIN_PASSWORD \
	--data-urlencode "q=CREATE DATABASE "$INFLUXDB_DB
curl -XPOST -G https://localhost:$INFLUXDB_PORT/query -u $INFLUXDB_ADMIN_USER:$INFLUXDB_ADMIN_PASSWORD \
	--data-urlencode "q=CREATE RETENTION POLICY "rp" ON "$INFLUXDB_DB" DURATION 7d REPLICATION 1 DEFAULT"
