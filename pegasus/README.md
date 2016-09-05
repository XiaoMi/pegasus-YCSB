<!--
Copyright (c) 2015 YCSB contributors. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You
may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License. See accompanying
LICENSE file.
-->

# YCSB Pegasus binding

This section describes how to run YCSB on Pegasus.

## 1. Start Pegasus service

Ask to Pegasus cluster manager to start the cluster.

## 2. Install Java and Maven

See step 2 in [`../mongodb/README.md`](../mongodb/README.md).

## 3. Set up YCSB

Git clone YCSB and compile:

    git clone git@git.n.xiaomi.com:pegasus/ycsb.git
    cd ycsb
    mvn -pl com.yahoo.ycsb:pegasus-binding -am clean package

## 4. Load data and run tests

Load the data:

    ./bin/ycsb load pegasus -s -P workloads/workloada > outputLoad.txt

Run the workload test:

    ./bin/ycsb run pegasus -s -P workloads/workloada > outputRun.txt

## 5. Pegasus Configuration

A default configuration file is provided in
[`conf/pegasus.properties`](conf/pegasus.properties).

You can specify configuration file on the command line via `-p`, e.g.:

    ./bin/ycsb load pegasus -s -P workloads/workloada \
        -p "pegasus.config=file://./pegasus.properties" > outputLoad.txt

If not specified, then use the default configuration file.

### Required configs

- `meta_servers`

  This is a comma-separated list of "host:port" providing the Pegasus interface.

### Optional configs

- `operation_timeout`

  Operation timeout in milliseconds.

- `retry_when_meta_loss`

  Retry time when connecting failed to meta servers.

