#!/bin/bash

#Old version (Alternative)
#docker pull petergrace/opentsdb-docker
#docker run -d -p 4242:4242 --name opentsdb0 petergrace/opentsdb-docker

#Download
#wget https://downloads.apache.org/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz
#wget https://downloads.apache.org/hbase/2.2.4/hbase-2.2.4-bin.tar.gz
#wget https://github.com/OpenTSDB/opentsdb/releases/download/v2.4.0/opentsdb-2.4.0.tar.gz 

#Extract
#tar xvzf hadoop-3.2.1.tar.gz
#tar xvzf hbase-2.2.4-bin.tar.gz
#tar xvzf opentsdb-2.4.0.tar.gz

#JAVA SDK
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.242.b08-0.el8_1.x86_64

#HADOOP INFRA
export HADOOP_USER=/home/hadoop
export HADOOP_HOME=$HADOOP_USER/hadoop/
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_INSTALL=$HADOOP_HOME
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export HBASE_HOME=$HADOOP_USER/hbase/
export OPENTSDB_HOME=$HADOOP_USER/opentsdb

#PATH
export PATH=$PATH:$HADOOP_USER/.local/bin:$HADOOP_USER/hadoop/bin
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export PATH=$PATH:$HBASE_HOME/bin
export PATH=$PATH:$OPENTSDB_HOME

#DAEMONS
hdfs --daemon start namenode
hdfs --daemon start secondarynamenode
hdfs --daemon start datanode
hdfs dfs -ls
hdfs dfs -ls /hbase
start-hbase.sh

nohup tsdb tsd --config=$OPENTSDB_HOME/src/opentsdb.conf --port=4242 --staticroot=$OPENTSDB_HOME/staticroot --cachedir=/tmp/tsdbtmp --zkquorum=localhost:2181 2>&1 >/tmp/opentsdb.log &
sleep 1
jps
