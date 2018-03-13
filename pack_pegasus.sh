#!/bin/sh

# first compile the package
mvn -Dcheckstyle.skip=true -DskipTests -pl com.yahoo.ycsb:pegasus-binding -am clean package

# get the version of ycsb
version=YCSB-`ls pegasus/target/pegasus-binding* | awk -F'binding-' '{print $2}' | awk -F'.jar' '{print $1}'`

# copy files
pkg_dir=pegasus-$version
rm -rf $pkg_dir &>/dev/null
mkdir $pkg_dir
cp -v pegasus/target/*.jar $pkg_dir
mkdir -p $pkg_dir/dependency
cp -v -R pegasus/target/dependency/* $pkg_dir/dependency

cp -v pegasus/conf/* $pkg_dir/
cp -v pegasus/bin/* $pkg_dir/
cp -v workloads/workload_pegasus $pkg_dir/
chmod +x $pkg_dir/*.sh

tar cfz $pkg_dir.tar.gz $pkg_dir

