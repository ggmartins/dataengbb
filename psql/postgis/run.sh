#!/bin/bash

docker run -d -p "127.0.0.1:6432:5432" \
  --hostname=postgres \
  --name=postgis-15 \
  --restart=always \
  -e POSTGRES_DB= \
  -e POSTGRES_USER= \
  -e POSTGRES_PASSWORD= \
  -v $PWD/data:/var/lib/postgresql/data \
  postgis/postgis:15-master
