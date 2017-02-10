#!/bin/bash

# servers that the ycsb will be send to, do not contain itself.
# the ycsb folder will be saved in the absolute path : /home/work
# also, the ycsb will be compiled.
# Usage:
#	./distribute_ycsb.sh <path_to_ycsb_folder>
#	if not provide <path_to_ycsb_folder>, default is ./ycsb

file=/home/work/ycsb #default
if [ -n "$1" ]; then
	file=$1
fi
echo "the ycsb path is: "$file

if [ ! -d "$file" ];then
	echo "ycsb folder is not exist."
	exit -1
fi

servers=(c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj)
server_nums=${#servers[@]}

for server in ${servers[@]}
do
	echo $server
	ssh $server "cd /home/work; rm -rf ycsb"
	scp -r $file work@$server:/home/work 1>/dev/null
	ssh $server "cd /home/work/ycsb; mvn -Dcheckstyle.skip=true -DskipTests -pl com.yahoo.ycsb:pegasus-binding -am clean package 1>/dev/null"	
done
