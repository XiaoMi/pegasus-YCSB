#!/bin/bash

# distribution
others=(c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj)
script=/home/work/ycsb/pegasus_d_run.sh
config=/home/work/ycsb/pegasus.properties
for server in ${others[*]}
do
  scp $script $server:$script
  scp $config $server:$config
done

all=(${others[*]} c4-hadoop-tst-st75.bj)
result=/home/work/ycsb/pegasus_ycsb_result/result
rm out.pegasus
for N in 30 50 100 200
do
  for server in ${all[*]}
  do
    ssh $server "cd /home/work/ycsb;sh $script $N &" &
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
    ssh $server "cat $result" >> out.pegasus
  done
done
