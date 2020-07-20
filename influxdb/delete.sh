#!/bin/bash

docker stop influxdb
docker rm influxdb
rm -Rf data 
rm -Rf meta 
rm -Rf wal 
