#!/bin/bash
#
# test pegasus ycsb with thread 1~50

outdir=pegasus_ycsb_result
rm -rf $outdir
mkdir -p $outdir
echo "Thread	Count	Runtime	QPS	AvgLat	P99Lat"
for T in {1..50}
do
  if [ $T -le 10 ]; then
    N=10000
  elif [ $T -le 20 ]; then
    N=50000
  elif [ $T -le 30 ]; then
    N=100000
  else
    N=200000
  fi
  #echo "Loading count=$N thread=$T ..."
  outfile=$outdir/load_t${T}.result
  ./bin/ycsb load pegasus -s -P pegasus/workloadw -p recordcount=$N -p operationcount=$N -threads $T &>$outfile
  RunTime=`cat $outfile | grep OVERALL| grep RunTime | awk '{print $3}' | cut -d. -f1`
  Throughput=`cat $outfile | grep '\[OVERALL\]'| grep Throughput | awk '{print $3}' | cut -d. -f1`
  AvgLatency=`cat $outfile | grep '\[INSERT\]' | grep AverageLatency | awk '{print $3}' | cut -d. -f1`
  P99Latency=`cat $outfile | grep '\[INSERT\]' | grep 99thPercentileLatency | awk '{print $3}' | cut -d. -f1`
  echo "$T	$N	$RunTime	$Throughput	$AvgLatency	$P99Latency"
done
