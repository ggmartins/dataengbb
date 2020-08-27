#!/bin/bash

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,lat=41.795,lng=-87.60,country=US,ispcity=Verizon\,\ Chicago\,IL metric=1 '$TS

curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,lat=40.345,lng=-74.61,country=US,ispcity=Comcast\,\ Princeton\,NJ metric=2 '$TS

curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,lat=37.368,lng=-122.036,country=US,ispcity=AT&T\,\ Sunnyvale\,CA metric=3 '$TS

curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,lat=47.606,lng=-122.332,country=US,ispcity=Charter\,\ Seattle\,WA metric=0 '$TS

curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'geometric,lat=40.712,lng=-74.005,country=US,ispcity=T-Mobile\,\ New\ York\,NY metric=-1 '$TS
