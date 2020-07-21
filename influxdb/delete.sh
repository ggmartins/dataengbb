#!/bin/bash

docker stop influxdb
docker rm influxdb
sudo rm -f $INFLUXDB_PATH/influxdb.cert.conf
sudo rm -Rf $INFLUXDB_PATH/cert
sudo rm -Rf $INFLUXDB_PATH/data 
sudo rm -Rf $INFLUXDB_PATH/meta 
sudo rm -Rf $INFLUXDB_PATH/wal 
