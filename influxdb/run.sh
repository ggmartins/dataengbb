#!/bin/bash

echo "copying $PWD/influxdb.cert.conf $INFLUXDB_PATH/influxdb.cert.conf"
cp $PWD/influxdb.cert.conf $INFLUXDB_PATH/influxdb.cert.conf
echo "copying $PWD/cert $INFLUXDB_PATH"
cp -R $PWD/cert $INFLUXDB_PATH/

docker run --rm \
	-e INFLUXDB_DB=$INFLUXDB_DB \
	-e INFLUXDB_HTTP_AUTH_ENABLED=true \
	-e INFLUXDB_ADMIN_USER=$INFLUXDB_ADMIN_USER \
	-e INFLUXDB_ADMIN_PASSWORD=$INFLUXDB_ADMIN_PASSWORD \
	-e INFLUXDB_USER=$INFLUXDB_USER \
	-e INFLUXDB_USER_PASSWORD=$INFLUXDB_USER_PASSWORD \
	-e INFLUXDB_READ_USER=$INFLUXDB_READ_USER \
	-e INFLUXDB_READ_USER_PASSWORD=$INFLUXDB_READ_USER_PASSWORD \
	-e INFLUXDB_WRITE_USER=$INFLUXDB_WRITE_USER \
	-e INFLUXDB_WRITE_USER_PASSWORD=$INFLUXDB_WRITE_USER_PASSWORD \
	-v $INFLUXDB_PATH:/var/lib/influxdb influxdb /init-influxdb.sh

docker run -p $INFLUXDB_PORT:8086 --name influxdb -d \
	-v $INFLUXDB_PATH:/var/lib/influxdb influxdb -config /var/lib/influxdb/influxdb.cert.conf
