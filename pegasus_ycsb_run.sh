#!/bin/bash
# the result is saving in the 'pegasus_ycsb_result' folder, ap=/home/work/ycsb/pegasus_ycsb_result.
# ycsb folder on the different server have the the absolute path [/home/work/ycsb]

# multi-servers to run the ycsb client.
servers=(c4-hadoop-tst-st71.bj c4-hadoop-tst-st72.bj c4-hadoop-tst-st73.bj c4-hadoop-tst-st74.bj c4-hadoop-tst-st75.bj)
server_nums=${#servers[@]}
server_name=`hostname`
script=pegasus_ycsb_run.sh
tmp_result=`pwd`/pegasus_ycsb_temp_result 
final_result=`pwd`/pegasus_ycsb_result
threads=(1 2 3 4 5 8 10 20 30 40 50 100)
commands_file=$final_result/commands.txt

function run_sendmail()
{
    email_address=$1
    myname=`hostname`
    result_file=$final_result/ycsb_result.txt
    rm -rf $result_file
    echo "Write result:" >> $result_file
    cat $final_result/write_result.txt >> $result_file
    echo "" >> $result_file
    echo "" >> $result_file
    echo "" >> $result_file
    echo "Read result:" >> $result_file
    cat $final_result/read_result.txt >> $result_file
    echo "" >> $result_file
    echo "" >> $result_file
    echo "To see the detailed information, please log in the server['$myname'], the result is under folder '$final_result'" >> $result_file
    echo "" >> $result_file
    echo "" >> $result_file
    echo "ycsb client:" >> $result_file
    for server in ${servers[@]}
    do
        echo "    $server" >> $result_file
    done
    echo "c4tst-pressure configuration:" >> $result_file
    echo "    replica-server number: 5" >> $result_file
    echo "    meta-server number: 2" >> $result_file
    echo "    table name: temp" >> $result_file
    echo "    partition number: 128" >> $result_file
    echo "" >> $result_file
    echo "" >> $result_file
    echo "ycsb commands:" >> $result_file
    cat $commands_file >> $result_file
    rm -rf $commands_file
    python -c 'from pegasus_tools import MailUtil
m = MailUtil(to_addrs="'$email_address'")
subject = "ycsb test result on c4tst-pressure"
fd = open("'$result_file'")
body = fd.read()
m.sendmaileasy(subject, body)
'
}

function run_merge_result()
{
    outfile=$final_result/$2_result.txt
    if [ ! -f "$outfile" ]; then
        echo "ThreadCount,QPS,AverageLatency(us),P99Latency(us)" >$outfile
    fi
    python -c 'from pegasus_tools import merge_result
servers = ["c4-hadoop-tst-st71.bj", "c4-hadoop-tst-st72.bj", "c4-hadoop-tst-st73.bj", "c4-hadoop-tst-st74.bj", "c4-hadoop-tst-st75.bj"]
merge_result( servers, "'$final_result'/'$1'", "'$2'", "'$outfile'" )'
}

function run_write_with_thread()
{
    thread_cnt=$1
    mkdir -p $tmp_result/write
    echo "ThreadCount,QPS,AverageLatency(us),P99Latency(us)" >$tmp_result/write.result_$server_name

    N=$((1000*thread_cnt*10))
    echo "Loading count=$N thread=$thread_cnt ..."
    outfile=$tmp_result/write/write_t${thread_cnt}.out
    ./bin/ycsb load pegasus -s -P pegasus/workloadw -p recordcount=$N -p operationcount=$N -threads $thread_cnt &>$outfile
    QPS=`cat $outfile | grep '\[OVERALL\].*Throughput' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    AVG=`cat $outfile | grep '\[INSERT\].*AverageLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    P99=`cat $outfile | grep '\[INSERT\].*99thPercentileLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    echo "$thread_cnt,$QPS,$AVG,$P99"
    echo "$thread_cnt,$QPS,$AVG,$P99" >>$tmp_result/write.result_$server_name
}

function run_read_with_thread()
{
    thread_cnt=$1
    mkdir -p $tmp_result/read
    echo "ThreadCount,QPS,AverageLatency(us),P99Latency(us)" >$tmp_result/read.result_$server_name
    
    N=$((1000*thread_cnt*10))
    echo "Reading count=$N thread=$thread_cnt ..."
    outfile=$tmp_result/read/read_t${thread_cnt}.out
    ./bin/ycsb run pegasus -s -P pegasus/workloadr -p recordcount=$N -p operationcount=$N -threads $thread_cnt &>$outfile
    QPS=`cat $outfile | grep '\[OVERALL\].*Throughput' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    AVG=`cat $outfile | grep '\[READ\].*AverageLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    P99=`cat $outfile | grep '\[READ\].*99thPercentileLatency' | grep -o '[0-9]*\.' | grep -o '[0-9]*'`
    echo "$thread_cnt,$QPS,$AVG,$P99"
    echo "$thread_cnt,$QPS,$AVG,$P99" >>$tmp_result/read.result_$server_name
}

function run_write()
{
    for T in ${threads[@]}
    do
        for ((i=0; i<$server_nums; i++))
        do
            echo ${servers[$i]}
            ssh ${servers[$i]} "cd /home/work/ycsb; bash $script write $T &" &
        done
        wait
        echo "    ./bin/ycsb load pegasus -s -P pegasus/workloadw -p recordcount=$((1000*T*10)) -p operationcount=$((1000*T*10)) -threads $T" >> $commands_file
        # collect data from other server.
        outdir=$final_result/$T
        mkdir -p $outdir
        for ((i=0; i<$server_nums; i++))
        do
            scp -r work@${servers[$i]}:$tmp_result/write.result_${servers[$i]} $outdir/write.result_${servers[$i]}
            ssh ${servers[$i]} "cd $tmp_result; rm -rf write.result_${servers[$i]}"
        done
        run_merge_result $T write
    done
}

function run_read()
{
    for T in ${threads[@]}
    do
        for ((i=0; i<$server_nums; i++))
        do
            echo ${servers[$i]}
            ssh ${servers[$i]} "cd /home/work/ycsb; bash $script read $T &" &
        done
        wait
        echo "    ./bin/ycsb run pegasus -s -P pegasus/workloadr -p recordcount=$((1000*T*10)) -p operationcount=$((1000*T*10)) -threads $T" >> $commands_file
        # collect data from other server.
        outdir=$final_result/$T
        mkdir -p $outdir
        for ((i=0; i<$server_nums; i++))
        do
            scp -r work@${servers[$i]}:$tmp_result/read.result_${servers[$i]} $outdir/read.result_${servers[$i]}
            ssh ${servers[$i]} "cd $tmp_result; rm -rf read.result_${servers[$i]}"
        done
        wait
        run_merge_result $T read
    done
}   

function run_write_read()
{
    rm -rf $commands_file
    echo "begin to run ycsb load..."
    run_write
    echo "begin to run ycsb run..."
    run_read
}

function run_ycsb_start()
{
    # clear the old data.
    for ((i=0; i<$server_nums; i++))
    do
        echo ${servers[$i]}
        ssh ${servers[$i]} "cd /home/work/ycsb; rm -rf $final_result; mkdir -p $final_result; rm -rf $tmp_result; mkdir -p $tmp_result"
    done
    run_write_read
    echo "finish testing, and send email..."
    run_sendmail pegasus-help@xiaomi.com
}

########################
#Usage:
# ./pegasus_ycsb_run.sh ycsb_start

cmd=$1
case $cmd in
    ycsb_start)
        run_ycsb_start
        ;;
    write)
        run_write_with_thread $2
        ;;
    read)
        run_read_with_thread $2
        ;;
    *)
        echo "execute shell error."
        exit -1
esac
