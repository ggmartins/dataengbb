#!/bin/bash

#influxdb queries
# SELECT "x" as a_x,"y" as a_y, "info" as a_info FROM "latent_space" where time > now() - 24h AND "color"='g'
# SELECT "x" as b_x,"y" as b_y, "info" as b_info FROM "latent_space" where time > now() - 24h AND "color"='r'
# SELECT "x" as c_x,"y" as c_y, "info" as c_info FROM "latent_space" where time > now() - 24h AND "color"='y'

TS=$(echo $(date +%s)'000000000')
echo "testing insert: "$TS

offset_x=$(echo $(seq 0 8))
offset_y=$(echo $(seq 0 1))

for o_x in $offset_x; do
  for o_y in $offset_y; do
    echo "offset $o_x, $o_y"

    X=($(awk -v n=200 -v seed="$RANDOM" 'BEGIN { srand(seed); for (i=0; i<n; ++i) printf("%.2f\n", rand()-0.5) }'))
    Y=($(awk -v n=200 -v seed="$RANDOM" 'BEGIN { srand(seed); for (i=0; i<n; ++i) printf("%.2f\n", rand()-0.5) }'))

    for i in ${!X[@]}; do
      rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
      if (( $(echo "$rad < 0.1" |bc -l) )); then 
        echo "inserting ${X[$i]},${Y[$i]} [$i]"
	x_x=$(echo ${X[$i]}" + "$o_x | bc)
	y_y=$(echo ${Y[$i]}" + "$o_y | bc)
	device_id=$(echo "dev"$o_x""$o_y)
	echo $device_id

	curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
  	  --header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	  --data-raw 'latent_space,ind='$i',color=g,device='$device_id',info=I\'"'"'m\ Green. x='$x_x','y=$y_y' '$TS
      fi
    done

    for i in ${!X[@]}; do
      rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
      if (( $(echo "$rad > 0.1" |bc -l) )); then 
        if (( $(echo "$rad < 0.15" |bc -l) )); then 
          echo "inserting ${X[$i]},${Y[$i]} [$i]"
    	  x_x=$(echo ${X[$i]}" + "$o_x | bc)
	  y_y=$(echo ${Y[$i]}" + "$o_y | bc)
	  device_id=$(echo "dev"$o_x""$o_y)
	  echo $device_id
 
          curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
  	    --header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	    --data-raw 'latent_space,ind='$i',color=y,device='$device_id',info=I\'"'"'m\ Yellow x='$x_x','y=$y_y' '$TS
        fi
      fi
    done

    c=0
    for i in ${!X[@]}; do
      rad=$(echo ${X[$i]}"^2 + "${Y[$i]}"^2" | bc)
      if (( $(echo "$rad > 0.15" |bc -l) )); then
        if [ $c -lt 6 ]; then
          echo "inserting ${X[$i]},${Y[$i]} [$i]"
          x_x=$(echo ${X[$i]}" + "$o_x | bc)
	  y_y=$(echo ${Y[$i]}" + "$o_y | bc)
  	  device_id=$(echo "dev"$o_x""$o_y)
	  echo $device_id
 
          curl -i -XPOST 'https://'$INFLUXDB_HOST':'$INFLUXDB_PORT'/api/v2/write?bucket='$INFLUXDB_DB'/rp&precision=ns' \
  	     --header 'Authorization: Token '$INFLUXDB_WRITE_USER':'$INFLUXDB_WRITE_USER_PASSWORD \
	     --data-raw 'latent_space,ind='$i',color=r,device='$device_id',info=I\'"'"'m\ Red. x='$x_x','y=$y_y' '$TS
          let "c=c+1"
        fi
      fi
    done

  done
done



curl -XPOST -G https://$INFLUXDB_HOST:$INFLUXDB_PORT/query \
	-u $INFLUXDB_READ_USER:$INFLUXDB_READ_USER_PASSWORD \
	--data-urlencode "q=SELECT * FROM $INFLUXDB_DB.rp.latent_space"
