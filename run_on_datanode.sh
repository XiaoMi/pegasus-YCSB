#!/bin/bash

all=(
  c4-hadoop-tst-st61.bj 
  c4-hadoop-tst-st62.bj 
  c4-hadoop-tst-st63.bj 
  c4-hadoop-tst-st64.bj 
  c4-hadoop-tst-st65.bj 
  c4-hadoop-tst-st66.bj 
  c4-hadoop-tst-st67.bj 
  c4-hadoop-tst-st68.bj 
  c4-hadoop-tst-st69.bj 
  c4-hadoop-tst-st70.bj 
)

for server in ${all[*]}
do
  scp drop_page_cache.sh root@$server:~
  echo $server
  ssh root@$server "sh /root/drop_page_cache.sh &"
done 
