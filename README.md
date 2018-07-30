<!--
Copyright (c) 2010 Yahoo! Inc., 2012 - 2016 YCSB contributors.
All rights reserved.

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

Yahoo! Cloud System Benchmark (YCSB)
====================================
[![Build Status](https://travis-ci.org/brianfrankcooper/YCSB.png?branch=master)](https://travis-ci.org/brianfrankcooper/YCSB)

Links
-----
http://wiki.github.com/brianfrankcooper/YCSB/  
https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark/
ycsb-users@yahoogroups.com  


Test Pegasus
------------

This section describes how to run YCSB on Pegasus.

## 1. Start Pegasus service

Ask to Pegasus cluster manager to [start the
cluster](https://github.com/XiaoMi/pegasus/wiki/%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2), and create table `usertable` for test.

If you want to use a different table name, please config the `table` option in 
[`workloads/workload_pegasus`](workloads/workload_pegasus).

## 2. Install Java and Maven

See step 2 in [`mongodb/README.md`](mongodb/README.md).

## 3. Set up YCSB

Before set up YCSB, you should install [Pegasus Java Client](https://github.com/XiaoMi/pegasus-java-client) firstly:

    wget https://github.com/XiaoMi/pegasus-java-client/archive/1.7.1-thrift-0.11.0-inlined-release.tar.gz
    tar xfz 1.7.1-thrift-0.11.0-inlined-release.tar.gz
    cd pegasus-java-client-1.7.1-thrift-0.11.0-inlined-release/
    mvn clean install -DskipTests

Git clone YCSB and build it:

    git clone https://github.com/XiaoMi/pegasus-YCSB.git
    cd pegasus-YCSB
    mvn -Dcheckstyle.skip=true -DskipTests -pl com.yahoo.ycsb:pegasus-binding -am clean package

## 4. Configuration

A default pegasus configuration file is provided in
[`pegasus/conf/pegasus.properties`](pegasus/conf/pegasus.properties).

A default log4j configuration file is provided in
[`pegasus/conf/log4j.properties`](pegasus/conf/log4j.properties).

Because `pegasus/conf` is added into classpath by default, so these configuration files will be 
found automatically.  Also You can specify configuration file on the command line via `-p`, e.g.:
    
    # example for specifying. If you have executed this command, skip the "Load the data" phase in section 5.
    ./bin/ycsb load pegasus -s -P workloads/workload_pegasus \
        -p "pegasus.config=file://./pegasus/conf/pegasus.properties" > outputLoad.txt

## 5. Load data and run tests

Load the data:

    ./bin/ycsb load pegasus -s -P workloads/workload_pegasus > outputLoad.txt

Run the workload test:

    ./bin/ycsb run pegasus -s -P workloads/workload_pegasus > outputRun.txt

## 6. Distributed running tests

Generate `pegasus-YCSB-${VERSION}.tar.gz` package:

    ./pack_pegasus.sh

Transfer package to target machines, then:

    tar xfz pegasus-YCSB-${VERSION}.tar.gz
    cd pegasus-YCSB-${VERSION}
    ./start.sh <load|run>

Getting Started
---------------

1. Download the [latest release of YCSB](https://github.com/brianfrankcooper/YCSB/releases/latest):

    ```sh
    curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.10.0/ycsb-0.10.0.tar.gz
    tar xfvz ycsb-0.10.0.tar.gz
    cd ycsb-0.10.0
    ```
    
2. Set up a database to benchmark. There is a README file under each binding 
   directory.

3. Run YCSB command. 

    On Linux:
    ```sh
    bin/ycsb.sh load basic -P workloads/workloada
    bin/ycsb.sh run basic -P workloads/workloada
    ```

    On Windows:
    ```bat
    bin/ycsb.bat load basic -P workloads\workloada
    bin/ycsb.bat run basic -P workloads\workloada
    ```

  Running the `ycsb` command without any argument will print the usage. 
   
  See https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  for a detailed documentation on how to run a workload.

  See https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties for 
  the list of available workload properties.

Building from source
--------------------

YCSB requires the use of Maven 3; if you use Maven 2, you may see [errors
such as these](https://github.com/brianfrankcooper/YCSB/issues/406).

To build the full distribution, with all database bindings:

    mvn clean package

To build a single database binding:

    mvn -pl com.yahoo.ycsb:mongodb-binding -am clean package
