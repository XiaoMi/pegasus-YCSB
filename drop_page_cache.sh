#!/bin/bash
while true; do
   sync
   echo 1 > /proc/sys/vm/drop_caches
   sleep 0.1
done
