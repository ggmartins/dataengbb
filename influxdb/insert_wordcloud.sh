#!/bin/bash

#SELECT sum("metric") as c FROM "wordmetric" WHERE time > now() - 24h GROUP BY word

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'wordmetric,info=test1,word=word1 metric=3 '$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'wordmetric,info=test2,word=word2 metric=1 '$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'wordmetric,info=tes2t,word=word3 metric=30 '$TS

curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	        -u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
		        --data-urlencode "q=SELECT * FROM $INFLUXDB_DB.rp.wordmetric"
