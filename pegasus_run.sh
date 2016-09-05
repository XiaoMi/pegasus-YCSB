#!/bin/bash

outdir=pegasus_result
rm -rf $outdir
mkdir -p $outdir

for T in 1 10 20 40 50
do
  N=$((1000*T*10))
  echo "Loading count=$N thread=$T ..."
  ./bin/ycsb load pegasus -s -P pegasus/workloadw -p recordcount=$N -p operationcount=$N -threads $T &>$outdir/load_t${T}.result
done

for T in 1 10 20 40 50
do
  N=$((1000*T*10))
  echo "Reading count=$N thread=$T ..."
  ./bin/ycsb run pegasus -s -P pegasus/workloadr -p recordcount=$N -p operationcount=$N -threads $T &>$outdir/read_t${T}.result
done

