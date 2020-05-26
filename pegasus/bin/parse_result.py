#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
python3 parse_result.py result.txt > benchmark_result.csv
"""

import sys
import os
import math
from typing import List

testIdToRWRatio = {
    "1": "0:1",
    "2": "3:1",
    "3": "30:1",
}


def failSymbolNotFound(what: str):
    raise ValueError(
        "invalid format of ycsb result [no '{}' is found], please check the file".format(what))


def findAttrKeyInValue(segments: List[str], key: str):
    for s in segments:
        if s.startswith(key):
            return s[len(key):].strip()
    failSymbolNotFound(key)


def parseNum(val: str):
    if 'E' in val:
        idx = val.index('E')
        power = int(val[idx + 1:])
        val = float(val[:idx]) * math.pow(10, power)
    return float(val)


def parseLine(line: str, resultTable):
    idx = line.find(":")
    if idx == -1:
        failSymbolNotFound(':')

    row = []

    # parse hashkey
    hashkey = line[:idx].strip().strip('"')
    # format: ycsb_1_load_workload_usertable_t10
    segments = hashkey.split('_')
    testId = segments[1]  # 1/2/3/4
    numThreads = segments[5]  # t10
    rwRatio = testIdToRWRatio[testId]
    testName = rwRatio + '+' + numThreads
    row.append(testName)

    # parse sortkey
    line = line[idx + 1:].strip()
    idx = line.find("=>")
    if idx == -1:
        failSymbolNotFound('=>')
    clientAddr = line[:idx].strip().strip('"')
    row.append(clientAddr)

    # parse value
    value = line[idx + 2:].strip()  # +2 to skip '=>'
    segments = value.split('\\n[OVERALL],')
    segments = list(map(str.strip, segments))
    # Time(s)
    runtimeStr = findAttrKeyInValue(segments, 'RunTime(ms),')
    runTimeSec = parseNum(runtimeStr) / 1000
    row.append(runTimeSec)

    # Insert
    segments = value.split('\\n[INSERT],')
    segments = list(map(str.strip, segments))
    # W-QPS
    ops = parseNum(findAttrKeyInValue(segments, 'Operations,'))
    qps = ops / runTimeSec
    # W-AVG-Lat
    avg = findAttrKeyInValue(segments, 'AverageLatency(us),')
    # W-P95-Lat
    p95 = findAttrKeyInValue(segments, '95.0thPercentileLatency(us),')
    # W-P99-Lat
    p99 = findAttrKeyInValue(segments, '99.0thPercentileLatency(us),')
    # W-P999-Lat
    p999 = findAttrKeyInValue(segments, '99.9thPercentileLatency(us),')
    # W-P9999-Lat
    p9999 = findAttrKeyInValue(segments, '99.99thPercentileLatency(us),')
    # W-MAX-Lat
    maxL = findAttrKeyInValue(segments, 'MaxLatency(us),')
    row = row + [int(qps), parseNum(avg), parseNum(p95), parseNum(
        p99), parseNum(p999), parseNum(p9999), parseNum(maxL)]

    # Read
    segments = value.split('\\n[READ],')
    if len(segments) > 1:
        segments = list(map(str.strip, segments))
        # R-QPS
        ops = parseNum(findAttrKeyInValue(segments, 'Operations,'))
        qps = ops / runTimeSec
        # R-AVG-Lat
        avg = findAttrKeyInValue(segments, 'AverageLatency(us),')
        # R-P95-Lat
        p95 = findAttrKeyInValue(segments, '95.0thPercentileLatency(us),')
        # R-P99-Lat
        p99 = findAttrKeyInValue(segments, '99.0thPercentileLatency(us),')
        # R-P999-Lat
        p999 = findAttrKeyInValue(segments, '99.9thPercentileLatency(us),')
        # R-P9999-Lat
        p9999 = findAttrKeyInValue(segments, '99.99thPercentileLatency(us),')
        # R-MAX-Lat
        maxL = findAttrKeyInValue(segments, 'MaxLatency(us),')
        row = row + [int(qps), parseNum(avg), parseNum(p95), parseNum(
            p99), parseNum(p999), parseNum(p9999), parseNum(maxL)]
    else:  # else: load mode, no read result.
        row = row + [0, 0, 0, 0, 0, 0, 0]

    if testName not in resultTable:
        resultTable[testName] = []
    resultTable[testName].append(row)


if __name__ == "__main__":
    file = sys.argv[1]
    if not os.path.isfile(file):
        print("no such file {}".format(file))
    f = open(file, "r")

    title = "RW Ratio+Threads,Client,Time(s),W-QPS,W-AVG-Lat,W-P95-Lat,W-P99-Lat,W-P999-Lat,W-P9999-Lat,W-MAX-Lat,R-QPS,R-AVG-Lat,R-P95-Lat,R-P99-Lat,R-P999-Lat,R-P9999-Lat,R-MAX-Lat"
    print(title)
    columnsNum = len(title.split(','))

    resultTable = {}
    [parseLine(line, resultTable) for line in f.readlines()]
    for testName, results in resultTable.items():
        aggregatedResult = [0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        assert len(aggregatedResult) + 2 == columnsNum

        for row in results:
            # sum up all columns except for the heading two columns
            aggregatedResult = [aggregatedResult[i] + row[i + 2]
                                for i in range(len(aggregatedResult))]
            print(','.join(list(map(str, row))))

        # calculate average value if not QPS column
        for i in range(len(aggregatedResult)):
            # leave it empty if no value
            if aggregatedResult[i] == 0:
                aggregatedResult[i] = ""
                continue
            if i == 1 or i == 8:
                continue
            # round to integer
            aggregatedResult[i] = int(aggregatedResult[i] / len(results))
        print(',,' + ','.join(list(map(str, aggregatedResult))))
