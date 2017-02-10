#####
Introduction:
    Using five server : c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj c4-hadoop-tst-st75.bj , to run ycsb-client, and test pegasus.
    The absoulte path of ycsb source code must be '/home/work/ycsb', if you need change, you should modify scripes: 'distribute_ycsb.sh' and 'pegasus_ycsb_run.sh'

#####
distribute_ycsb.sh: 
    This script is using to distribute the ycsb-source-code to different server, default absoulte path is /home/work/ycsb

######
pegasus_tools.py: 
    This script define the function that merge the result from different server to single file, and always be called by pegasus_ycsb_run.sh

#####
pegasus_ycsb_run.sh
    This script define how to using five servers(default, if you need add or remove the servers, please modify this script) to run ycsb client,
    to start test, you should run the this script with parameter ycsb_start, like this: './pegasus_ycsb_run.sh ycsb_start' or 'bash pegasus_ycsb_run.sh ycsb_start'
    
    The server that running this script is a central-controller, it will control other five servers to run the ycsb_client at the same time.

##### 
Default Usage:
    First, download the ycsb source code on one server.
    Second, modify the meta_servers in the file 'pegasus/conf/pegasus.properties' to the cluster address that you want test.
    Third, complie the source code, mvn -Dcheckstyle.skip=true -DskipTests -pl com.yahoo.ycsb:pegasus-binding -am clean package
    Fourth, run the 'distribute_ycsb.sh' to distribute the ycsb code to other server, this script will compile on each server.
    Finally, start the ycsb test
            './pegasus_ycsb_run.sh ycsb_start'
            or
            'bash pegasus_ycsb_run.sh ycsb_start'
