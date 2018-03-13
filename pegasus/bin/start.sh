#!/bin/bash

if [ $# -ne 1 ]; then
    echo "USAGE: $0 <load|run>"
    exit 1
fi

type=""
if [ "$1" == "load" ]; then
    phase="-load"
elif [ "$1" == "run" ]; then
    phase="-t"
else
    echo "USAGE: $0 <load|run>"
    exit 1
fi

java -cp .:./*:dependency/* com.yahoo.ycsb.Client \
    -db com.yahoo.ycsb.db.PegasusClient \
    -p pegasus.config=file://./pegasus.properties \
    -s -P ./workload_pegasus $phase

