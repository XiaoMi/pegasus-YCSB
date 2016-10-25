#!/bin/bash

# distribution
others=(c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj)
script=/home/work/ycsb/hbase_d_run.sh
for server in ${others[*]}
do
  scp $script $server:$script
done

all=(${others[*]} c4-hadoop-tst-st75.bj)
result=/home/work/ycsb/hbase_ycsb_result/result
rm out.hbase
for N in 30 50 100 200
  do
  for server in ${all[*]}
  do
    ssh $server "sh $script $N &" &
  done

  sleep 5
  for server in ${all[*]}
  do
    ssh $server "test -f $result"
    while [ $? -ne 0 ]
    do 
      sleep 5
      ssh $server "test -f $result"
    done
    ssh $server "cat $result" >> out.hbase
  done
done
