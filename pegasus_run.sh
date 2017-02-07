#!/bin/bash
#
# test pegasus ycsb READ/WRITE with different thread count

outdir=pegasus_result
rm -rf $outdir
mkdir -p $outdir
mkdir -p $outdir/write
mkdir -p $outdir/read

echo "ThreadCount,QPS,AverageLatency,P99Latency" >$outdir/write.result
for T in 1 2 3 4 5 8 10 20 30 40 50 100
do
  N=$((1000*T*10))
  echo "Loading count=$N thread=$T ..."
  outfile=$outdir/write/write_t${T}.out
  ./bin/ycsb load pegasus -s -P pegasus/workloadw -p recordcount=$N -p operationcount=$N -threads $T &>$outfile
  QPS=`cat $outfile | grep '\[OVERALL\].*Throughput' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  AVG=`cat $outfile | grep '\[INSERT\].*AverageLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  P99=`cat $outfile | grep '\[INSERT\].*99thPercentileLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  echo "$T,$QPS,$AVG,$P99"
  echo "$T,$QPS,$AVG,$P99" >>$outdir/write.result
done

echo "ThreadCount,QPS,AverageLatency,P99Latency" >$outdir/read.result
for T in 1 2 3 4 5 8 10 20 30 40 50 100
do
  N=$((1000*T*10))
  echo "Reading count=$N thread=$T ..."
  outfile=$outdir/read/read_t${T}.out
  ./bin/ycsb run pegasus -s -P pegasus/workloadr -p recordcount=$N -p operationcount=$N -threads $T &>$outfile
  QPS=`cat $outfile | grep '\[OVERALL\].*Throughput' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  AVG=`cat $outfile | grep '\[READ\].*AverageLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  P99=`cat $outfile | grep '\[READ\].*99thPercentileLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
  echo "$T,$QPS,$AVG,$P99"
  echo "$T,$QPS,$AVG,$P99" >>$outdir/read.result
done

