#!/bin/bash

#influxdb queries
# SELECT "x" as a_x,"y" as a_y, "info" as a_info FROM "latent_space" where time > now() - 24h AND "color"='g'
# SELECT "x" as b_x,"y" as b_y, "info" as b_info FROM "latent_space" where time > now() - 24h AND "color"='r'
 #SELECT "x" as c_x,"y" as c_y, "info" as c_info FROM "latent_space" where time > now() - 24h AND "color"='y'

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS

X=($(awk -v n=200 -v seed="$RANDOM" 'BEGIN { srand(seed); for (i=0; i<n; ++i) printf("%.2f\n", rand()-0.5) }'))
Y=($(awk -v n=200 -v seed="$RANDOM" 'BEGIN { srand(seed); for (i=0; i<n; ++i) printf("%.2f\n", rand()-0.5) }'))

for i in ${!X[@]}; do
  rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
  if (( $(echo "$rad < 0.1" |bc -l) )); then 
    echo "inserting ${X[$i]},${Y[$i]} [$i]"
    curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
	--header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	--data-raw 'latent_space,ind='$i',color=g,info=I\'"'"'m\ Green. x='${X[$i]}','y=${Y[$i]}' '$TS
  fi
done

for i in ${!X[@]}; do
  rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
  if (( $(echo "$rad > 0.1" |bc -l) )); then 
    if (( $(echo "$rad < 0.15" |bc -l) )); then 
       echo "inserting ${X[$i]},${Y[$i]} [$i]"
       curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
  	  --header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	  --data-raw 'latent_space,ind='$i',color=y,info=I\'"'"'m\ Yellow x='${X[$i]}','y=${Y[$i]}' '$TS
    fi
  fi
done

c=0
for i in ${!X[@]}; do
  rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
  if (( $(echo "$rad > 0.15" |bc -l) )); then
    if [ $c -lt 6 ]; then
       echo "inserting ${X[$i]},${Y[$i]} [$i]"
       curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
  	  --header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	  --data-raw 'latent_space,ind='$i',color=r,info=I\'"'"'m\ Red. x='${X[$i]}','y=${Y[$i]}' '$TS
       let "c=c+1"
    fi
  fi
done


curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "q=SELECT * FROM $INFLUXDB_DB.rp.latent_space"
