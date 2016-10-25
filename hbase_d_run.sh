#!/bin/bash
#
# Please remove pom.xml then execute this script

outdir=/home/work/ycsb/hbase_ycsb_result
result=/home/work/ycsb/hbase_ycsb_result/result
rm -rf $outdir
mkdir -p $outdir
echo `hostname` >> $result.tmp
echo "Thread	Count	Runtime	QPS	AvgLat	P99Lat" >> $result.tmp
T=$1
N=20000000
#echo "Loading count=$N thread=$T ..."
outfile=$outdir/load_t${T}.result
/home/work/ycsb/bin/ycsb run hbase094 -cp /home/work/ycsb/hbase/conf:/home/work/ycsb/core/target/*:/home/work/ycsb/hbase094/target/dependency/* -s -P /home/work/ycsb/pegasus/workloadr -p columnfamily=family -p recordcount=$N -p operationcount=$N -threads $T &>$outfile
RunTime=`cat $outfile | grep OVERALL| grep RunTime | awk '{print $3}' | cut -d. -f1`
Throughput=`cat $outfile | grep OVERALL| grep Throughput | awk '{print $3}' | cut -d. -f1`
AvgLatency=`cat $outfile | grep READ] | grep AverageLatency | awk '{print $3}' | cut -d. -f1`
P99Latency=`cat $outfile | grep READ] | grep 99thPercentileLatency | awk '{print $3}' | cut -d. -f1`
echo "$T	$N	$RunTime	$Throughput	$AvgLatency	$P99Latency" >> $result.tmp
echo "" >> $result.tmp
mv $result.tmp $result
