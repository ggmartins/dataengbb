#!/bin/bash

docker run -d --name grafana1 -p 8088:3000 -v $PWD/etc/grafana:/etc/grafana grafana/grafana
