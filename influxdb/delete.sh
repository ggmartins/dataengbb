#!/bin/bash

docker stop influxdb
docker rm influxdb
rm -f $INFLUXDB_PATH/influxdb.cert.conf
rm -Rf $INFLUXDB_PATH/cert
rm -Rf $INFLUXDB_PATH/data 
rm -Rf $INFLUXDB_PATH/meta 
rm -Rf $INFLUXDB_PATH/wal 
