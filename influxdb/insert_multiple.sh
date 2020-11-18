#!/bin/bash

TS=$(echo $(date +%s)'000000000')
echo "testing "$TS
curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-binary $'network_traffic_application_kbpsdw,deployment=iotlab,device=Apple_b7,application=Unknown value=1.0 1605717280000000000\nnetwork_traffic_application_kbpsdw,deployment=iotlab,device=Apple_b8,application=Unknown value=2.0 1605717280000000000'

